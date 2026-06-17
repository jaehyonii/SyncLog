import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { UserEntity } from '../users/user.entity';

/** Injects the authenticated UserEntity (set by JwtStrategy) into a handler. */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): UserEntity => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
