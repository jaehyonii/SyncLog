import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { UserEntity } from '../users/user.entity';
import { userToPerson } from '../teams/serializers';
import { AuthService } from './auth.service';
import { CurrentUser } from './current-user.decorator';
import { LoginDto, SignupDto } from './dto/auth.dto';
import { JwtAuthGuard } from './jwt-auth.guard';

/**
 *   POST /api/v1/auth/signup  { name, email, password } -> { token, user }
 *   POST /api/v1/auth/login   { email, password }       -> { token, user }
 *   GET  /api/v1/auth/me      (Bearer)                  -> Person
 */
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('signup')
  signup(@Body() dto: SignupDto) {
    return this.auth.signup(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@CurrentUser() user: UserEntity) {
    return userToPerson(user);
  }
}
