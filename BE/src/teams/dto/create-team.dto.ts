import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

/**
 * One part (role) the leader defines at creation: a display name (preset or
 * custom), an optional glyph for its icon, and whether it's the leader's own
 * part. Exactly one part should be `mine: true`; the rest become invite slots
 * with their own per-part code.
 */
export class CreateTeamPartDto {
  @IsString()
  @IsNotEmpty({ message: '파트 이름을 입력해 주세요.' })
  name: string;

  @IsOptional()
  @IsString()
  instrument?: string;

  @IsOptional()
  @IsBoolean()
  mine?: boolean;
}

/**
 * Create-team payload. The client posts a full `Team.toJson()`; the server is
 * the source of truth, so it only reads the fields below and (re)builds the
 * slot tracks + initial commit itself. Unknown fields (id, members, timeline)
 * are stripped by the global ValidationPipe.
 *
 * Roles: when `parts` is provided, each entry defines a part the leader named.
 * The `mine` part is claimed by the creator; the others are seeded with their
 * own invite code. Without `parts`, the server falls back to a default lineup
 * sized by `memberCount`.
 */
export class CreateTeamDto {
  @IsString()
  @IsNotEmpty({ message: '팀 이름을 입력해 주세요.' })
  name: string;

  @IsOptional()
  @IsString()
  song?: string;

  @IsOptional()
  @IsString()
  artist?: string;

  @IsOptional()
  @IsInt()
  bpm?: number;

  @IsOptional()
  @IsInt()
  memberCount?: number;

  @IsOptional()
  @IsInt()
  coverColor?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateTeamPartDto)
  parts?: CreateTeamPartDto[];

  @IsOptional()
  @IsArray()
  tracks?: unknown[];
}
