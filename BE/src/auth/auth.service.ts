import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcryptjs';
import { Repository } from 'typeorm';
import { avatarColor, initialOf } from '../common/avatar';
import { UserEntity } from '../users/user.entity';
import { userToPerson } from '../teams/serializers';
import { LoginDto, SignupDto, UpdateProfileDto } from './dto/auth.dto';

/**
 * Authentication: account creation + credential checks, issuing a JWT the
 * client stores and sends as `Authorization: Bearer <token>`. Passwords are
 * stored only as bcrypt hashes. Replaces the app's on-device mock auth once the
 * client is pointed at this server.
 */
@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
    private readonly jwt: JwtService,
  ) {}

  async signup(dto: SignupDto) {
    const name = dto.name.trim();
    const email = dto.email.trim().toLowerCase();
    if (!name) throw new BadRequestException('이름을 입력해 주세요.');

    const existing = await this.users.findOne({ where: { email } });
    if (existing) throw new ConflictException('이미 가입된 이메일이에요.');

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = this.users.create({
      name,
      email,
      passwordHash,
      initial: initialOf(name),
      // Seed the avatar color from the (stable, unique) email.
      color: String(avatarColor(email)),
    });
    const saved = await this.users.save(user);
    return this.tokenResponse(saved);
  }

  async login(dto: LoginDto) {
    const email = dto.email.trim().toLowerCase();
    const user = await this.users.findOne({ where: { email } });
    // Same message whether the email or password is wrong — don't reveal which.
    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 올바르지 않아요.');
    }
    return this.tokenResponse(user);
  }

  /**
   * Edit the signed-in user's profile. Only supplied fields change; renaming
   * also refreshes the initials avatar, and a new email is checked for clashes.
   * Returns the updated Person (the existing token stays valid).
   */
  async updateProfile(user: UserEntity, dto: UpdateProfileDto) {
    if (dto.name !== undefined) {
      const name = dto.name.trim();
      if (!name) throw new BadRequestException('이름을 입력해 주세요.');
      user.name = name;
      user.initial = initialOf(name);
    }

    if (dto.email !== undefined) {
      const email = dto.email.trim().toLowerCase();
      if (email !== user.email) {
        const clash = await this.users.findOne({ where: { email } });
        if (clash) throw new ConflictException('이미 가입된 이메일이에요.');
        user.email = email;
      }
    }

    if (dto.password !== undefined) {
      user.passwordHash = await bcrypt.hash(dto.password, 10);
    }

    const saved = await this.users.save(user);
    return userToPerson(saved);
  }

  private tokenResponse(user: UserEntity) {
    const token = this.jwt.sign({ sub: user.id, email: user.email });
    return { token, user: userToPerson(user) };
  }
}
