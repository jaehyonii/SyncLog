import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';

export class SignupDto {
  @IsString()
  @IsNotEmpty({ message: '이름을 입력해 주세요.' })
  name: string;

  @IsEmail({}, { message: '올바른 이메일 형식이 아니에요.' })
  email: string;

  @MinLength(6, { message: '비밀번호는 6자 이상이어야 해요.' })
  password: string;
}

export class LoginDto {
  @IsEmail({}, { message: '올바른 이메일 형식이 아니에요.' })
  email: string;

  @IsString()
  @IsNotEmpty({ message: '비밀번호를 입력해 주세요.' })
  password: string;
}

/**
 * Edit-profile payload for PATCH /auth/me. Every field is optional — only the
 * ones present are changed. `password` (when present) must still clear the 6+
 * char bar; `email` must be a valid, not-already-taken address.
 */
export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: '이름을 입력해 주세요.' })
  name?: string;

  @IsOptional()
  @IsEmail({}, { message: '올바른 이메일 형식이 아니에요.' })
  email?: string;

  @IsOptional()
  @MinLength(6, { message: '비밀번호는 6자 이상이어야 해요.' })
  password?: string;
}
