import {
  IsArray,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';

/**
 * Create-team payload. The client posts a full `Team.toJson()`; the server is
 * the source of truth, so it only reads the fields below and (re)builds the
 * open-slot tracks + initial commit itself. Unknown fields (id, members,
 * timeline) are stripped by the global ValidationPipe. Member count comes from
 * an explicit `memberCount` or, failing that, the length of the posted tracks.
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
  tracks?: unknown[];
}
