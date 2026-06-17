import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';

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
