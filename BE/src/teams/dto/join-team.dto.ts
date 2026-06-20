import { IsNotEmpty, IsString } from 'class-validator';

/** Body for POST /teams/join — the shareable code that adds the user to a team. */
export class JoinTeamDto {
  @IsString()
  @IsNotEmpty({ message: '초대 코드를 입력해 주세요.' })
  code: string;
}
