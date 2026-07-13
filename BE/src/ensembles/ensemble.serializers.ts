import { EnsembleEntity } from './entities/ensemble.entity';

/**
 * Maps an ensemble row to the JSON the Flutter client deserializes
 * (`FE/lib/domain/entities/ensemble.dart` `Ensemble.fromJson`). Team fields and
 * the member roster are already denormalized on the row, so no joins are needed.
 */
export function ensembleToJson(e: EnsembleEntity) {
  return {
    id: e.id,
    teamId: e.teamId,
    teamName: e.teamName,
    song: e.song,
    coverColor: Number(e.coverColor), // bigint comes back as a string from pg
    day: e.day,
    status: e.status,
    videoUrl: e.videoUrl ?? null,
    thumbnailUrl: e.thumbnailUrl ?? null,
    members: e.members ?? [],
    createdAt: e.createdAt.toISOString(),
  };
}
