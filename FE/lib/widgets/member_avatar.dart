import 'package:flutter/material.dart';
import '../domain/entities/person.dart';
import '../theme/tokens.dart';

/// A member avatar — deterministic initials on the member's brand color, or a
/// dashed "+" placeholder for an empty seat.
class MemberAvatar extends StatelessWidget {
  final Person? person;
  final double size;
  final bool ring;

  const MemberAvatar({
    super.key,
    required this.person,
    this.size = 32,
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    if (person == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: SL.surfaceMuted,
          shape: BoxShape.circle,
          border: Border.all(color: SL.border, style: BorderStyle.solid),
        ),
        child: Icon(Icons.add, size: size * 0.5, color: SL.textPlaceholder),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: person!.color,
        shape: BoxShape.circle,
        border: Border.all(color: SL.paper, width: 2),
        boxShadow: ring
            ? [
                BoxShadow(color: SL.rec, spreadRadius: 2),
                BoxShadow(color: SL.paper, spreadRadius: 4),
              ]
            : null,
      ),
      child: Text(
        person!.initial,
        style: SLType.sans(
          size: size * 0.42,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// A compact row of overlapping member avatars with a `+N` overflow chip.
class MemberStack extends StatelessWidget {
  final List<Person> members;
  final double size;
  final int max;

  const MemberStack({
    super.key,
    required this.members,
    this.size = 28,
    this.max = 4,
  });

  @override
  Widget build(BuildContext context) {
    final shown = members.take(max).toList();
    final extra = members.length - shown.length;
    final overlap = size * 0.32;

    // Overlap each avatar leftward over its predecessor.
    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < shown.length; i++)
            Transform.translate(
              offset: Offset(i == 0 ? 0 : -overlap * i, 0),
              child: MemberAvatar(person: shown[i], size: size),
            ),
          if (extra > 0)
            Transform.translate(
              offset: Offset(-overlap * shown.length, 0),
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SL.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: SL.paper, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: SLType.sans(
                    size: size * 0.36,
                    weight: FontWeight.w700,
                    color: SL.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
