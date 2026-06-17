import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

/**
 * A registered account — the server-side equivalent of the app's on-device
 * Account, plus the avatar fields the client's Person carries. Serialized to
 * the client as a Person via `userToPerson` (never including passwordHash).
 */
@Entity('users')
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Index({ unique: true })
  @Column()
  email: string;

  @Column()
  passwordHash: string;

  /** First grapheme of the name (initials avatar). */
  @Column()
  initial: string;

  /**
   * Avatar color as an 0xAARRGGBB int. Stored as bigint because the alpha byte
   * pushes opaque colors past PostgreSQL's signed `integer` range; the pg
   * driver returns bigint as a string, so serializers wrap it in `Number()`.
   */
  @Column({ type: 'bigint' })
  color: string;

  @CreateDateColumn()
  createdAt: Date;
}
