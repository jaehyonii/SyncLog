import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { existsSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { AppModule } from './app.module';

async function bootstrap() {
  // Ensure the upload destination exists before Multer writes to it.
  const uploadDir = join(process.cwd(), 'uploads');
  if (!existsSync(uploadDir)) mkdirSync(uploadDir, { recursive: true });

  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // All routes live under /api/v1 to match the client's contract.
  app.setGlobalPrefix('api/v1');

  // The Flutter client calls cross-origin (web/dev); allow it.
  app.enableCors();

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // strip unknown fields (client posts full Team objects)
      transform: true,
    }),
  );

  // Serve uploaded takes so `videoUrl` is reachable.
  app.useStaticAssets(uploadDir, { prefix: '/uploads/' });

  const port = parseInt(process.env.PORT ?? '3000', 10);
  await app.listen(port, '0.0.0.0');
  // eslint-disable-next-line no-console
  console.log(`SyncLog API listening on http://0.0.0.0:${port}/api/v1`);
}

void bootstrap();
