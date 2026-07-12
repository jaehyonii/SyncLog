import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { spawn } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { existsSync } from 'node:fs';
import { basename, join } from 'node:path';
import { UPLOAD_DIR } from '../teams/teams.controller';

/** A single part's take to place in the grid. */
export interface RenderTrack {
  videoUrl: string;
  syncOffsetMs: number;
}

export interface RenderResult {
  videoUrl: string;
  thumbnailUrl: string;
}

/** Square output canvas (px). Cells subdivide this. */
const CANVAS = 720;
/** Hard caps so one bad/long render can't hog the box. */
const MAX_DURATION_S = 180;
const FALLBACK_DURATION_S = 15;
const RENDER_TIMEOUT_MS = 5 * 60 * 1000;

/**
 * Composites a day's part takes into ONE ensemble MP4 (grid layout + mixed
 * audio) with ffmpeg. This is the single "완성된 합주영상" the SNS feed shows —
 * a real, shareable file, not the client-side synced multitrack playback.
 *
 * Robustness choices (phone takes vary wildly in codec/rotation/fps/length):
 *  - every input is re-scaled/cropped/fps-normalized before stacking;
 *  - each part's `syncOffsetMs` is applied as a lead-in delay (positive) or a
 *    head trim (negative), matching the client's "playback delay" semantics;
 *  - all streams are padded/trimmed to the longest input so nobody gets cut and
 *    the grid never desyncs;
 *  - the whole thing is bounded by a duration cap and a hard process timeout.
 */
@Injectable()
export class EnsembleRenderService {
  private readonly logger = new Logger(EnsembleRenderService.name);

  constructor(private readonly config: ConfigService) {}

  private publicUrl(): string {
    return this.config
      .get<string>('PUBLIC_URL', 'http://localhost:3000')
      .replace(/\/$/, '');
  }

  /** Map a stored `videoUrl` back to its local file by basename (robust to a
   * changed PUBLIC_URL between upload and render). */
  private localPath(videoUrl: string): string | null {
    let name: string;
    try {
      name = basename(new URL(videoUrl).pathname);
    } catch {
      name = basename(videoUrl);
    }
    const path = join(UPLOAD_DIR, name);
    return existsSync(path) ? path : null;
  }

  /**
   * Render the ensemble for a set of tracks. Throws on any failure (caller marks
   * the ensemble 'failed'); returns the public URLs on success.
   */
  async renderDay(tracks: RenderTrack[]): Promise<RenderResult> {
    const inputs = tracks
      .map((t) => ({ path: this.localPath(t.videoUrl), offset: t.syncOffsetMs }))
      .filter((t): t is { path: string; offset: number } => t.path != null);

    if (inputs.length === 0) {
      throw new Error('no usable take files to render');
    }

    const maxDur = await this.longestDuration(inputs.map((i) => i.path));

    const n = inputs.length;
    const cols = Math.ceil(Math.sqrt(n));
    const rows = Math.ceil(n / cols);
    const cellW = even(Math.floor(CANVAS / cols));
    const cellH = even(Math.floor(CANVAS / rows));
    const cells = cols * rows;

    const parts: string[] = [];

    // --- video: normalize + sync + pad/trim every input to exactly maxDur ---
    for (let i = 0; i < n; i++) {
      const offSec = inputs[i].offset / 1000;
      let f = `[${i}:v]scale=${cellW}:${cellH}:force_original_aspect_ratio=increase,crop=${cellW}:${cellH},fps=30,setpts=PTS-STARTPTS`;
      if (offSec > 0) f += `,tpad=start_duration=${offSec.toFixed(3)}`;
      else if (offSec < 0)
        f += `,trim=start=${(-offSec).toFixed(3)},setpts=PTS-STARTPTS`;
      // clamp to exactly maxDur (pad frozen/black tail, then cut)
      f += `,tpad=stop_duration=${maxDur.toFixed(3)},trim=end=${maxDur.toFixed(3)},setpts=PTS-STARTPTS[v${i}]`;
      parts.push(f);
    }
    // black filler cells for an incomplete grid
    for (let k = 0; k < cells - n; k++) {
      parts.push(
        `color=c=black:s=${cellW}x${cellH}:r=30:d=${maxDur.toFixed(3)}[f${k}]`,
      );
    }

    // --- assemble the grid ---
    let videoOut: string;
    if (cells === 1) {
      videoOut = '[v0]';
    } else {
      const cellLabels: string[] = [];
      for (let i = 0; i < n; i++) cellLabels.push(`[v${i}]`);
      for (let k = 0; k < cells - n; k++) cellLabels.push(`[f${k}]`);
      const layout: string[] = [];
      for (let c = 0; c < cells; c++) {
        const col = c % cols;
        const row = Math.floor(c / cols);
        layout.push(`${col * cellW}_${row * cellH}`);
      }
      parts.push(
        `${cellLabels.join('')}xstack=inputs=${cells}:layout=${layout.join('|')}[vout]`,
      );
      videoOut = '[vout]';
    }

    // --- audio: delay/trim + pad/trim to maxDur, then mix ---
    for (let i = 0; i < n; i++) {
      const offMs = inputs[i].offset;
      let a = `[${i}:a]aresample=48000,asetpts=PTS-STARTPTS`;
      if (offMs > 0) a += `,adelay=${offMs}:all=1`;
      else if (offMs < 0)
        a += `,atrim=start=${(-offMs / 1000).toFixed(3)},asetpts=PTS-STARTPTS`;
      a += `,apad,atrim=end=${maxDur.toFixed(3)},asetpts=PTS-STARTPTS[a${i}]`;
      parts.push(a);
    }
    const audioLabels = Array.from({ length: n }, (_, i) => `[a${i}]`).join('');
    parts.push(
      `${audioLabels}amix=inputs=${n}:normalize=1:dropout_transition=0[aout]`,
    );

    const outName = `${randomUUID()}.mp4`;
    const outPath = join(UPLOAD_DIR, outName);
    const args = ['-y'];
    for (const inp of inputs) args.push('-i', inp.path);
    args.push(
      '-filter_complex',
      parts.join(';'),
      '-map',
      videoOut,
      '-map',
      '[aout]',
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-pix_fmt',
      'yuv420p',
      '-c:a',
      'aac',
      '-movflags',
      '+faststart',
      '-t',
      maxDur.toFixed(3),
      outPath,
    );

    await this.run('ffmpeg', args, RENDER_TIMEOUT_MS);

    // thumbnail (first frame of the composited video)
    const thumbName = `${randomUUID()}.jpg`;
    const thumbPath = join(UPLOAD_DIR, thumbName);
    await this.run(
      'ffmpeg',
      ['-y', '-i', outPath, '-frames:v', '1', '-q:v', '3', thumbPath],
      60 * 1000,
    );

    const base = this.publicUrl();
    return {
      videoUrl: `${base}/uploads/${outName}`,
      thumbnailUrl: `${base}/uploads/${thumbName}`,
    };
  }

  /** Longest input duration (seconds), clamped to sane bounds. */
  private async longestDuration(paths: string[]): Promise<number> {
    let max = 0;
    for (const p of paths) {
      const d = await this.probeDuration(p);
      if (d > max) max = d;
    }
    if (!Number.isFinite(max) || max <= 0) max = FALLBACK_DURATION_S;
    return Math.min(max, MAX_DURATION_S);
  }

  private async probeDuration(path: string): Promise<number> {
    try {
      const out = await this.capture('ffprobe', [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'csv=p=0',
        path,
      ]);
      const d = parseFloat(out.trim());
      return Number.isFinite(d) ? d : 0;
    } catch {
      return 0;
    }
  }

  /** Run a process to completion; reject on non-zero exit or timeout (SIGKILL). */
  private run(cmd: string, args: string[], timeoutMs: number): Promise<void> {
    return new Promise((resolve, reject) => {
      const child = spawn(cmd, args);
      let stderr = '';
      const timer = setTimeout(() => {
        child.kill('SIGKILL');
        reject(new Error(`${cmd} timed out after ${timeoutMs}ms`));
      }, timeoutMs);
      child.stderr.on('data', (d) => {
        stderr += d.toString();
        if (stderr.length > 8000) stderr = stderr.slice(-8000);
      });
      child.on('error', (err) => {
        clearTimeout(timer);
        reject(err);
      });
      child.on('close', (code) => {
        clearTimeout(timer);
        if (code === 0) resolve();
        else {
          this.logger.error(`${cmd} exited ${code}: ${stderr.slice(-1000)}`);
          reject(new Error(`${cmd} exited with code ${code}`));
        }
      });
    });
  }

  /** Run a process and resolve its stdout. */
  private capture(cmd: string, args: string[]): Promise<string> {
    return new Promise((resolve, reject) => {
      const child = spawn(cmd, args);
      let stdout = '';
      child.stdout.on('data', (d) => (stdout += d.toString()));
      child.on('error', reject);
      child.on('close', (code) =>
        code === 0 ? resolve(stdout) : reject(new Error(`${cmd} exited ${code}`)),
      );
    });
  }
}

/** Round down to an even number (h264/yuv420p requires even dimensions). */
function even(n: number): number {
  const v = Math.max(2, Math.floor(n));
  return v % 2 === 0 ? v : v - 1;
}
