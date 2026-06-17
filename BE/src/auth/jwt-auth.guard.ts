import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/** Protects a route: requires a valid Bearer token (the 'jwt' strategy). */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
