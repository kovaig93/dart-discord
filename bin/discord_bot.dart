import 'dart:io';
import 'package:nyxx/nyxx.dart';

void main() async {
  String token = Platform.environment['TOKEN'] ?? '';

  final client = await Nyxx.connectGateway(
    token,
    GatewayIntents.all | GatewayIntents.messageContent,
  );

  final bot = await client.users.fetchCurrentUser();
  print("✅ Bot is online");

  client.onMessageCreate.listen((event) async {
    final content = event.message.content.trim();

    // Only allow commands from a specific user
    if (event.message.author.id.toString() != '1300544825371656202') return;

    // Respond to bot mention
    if (event.mentions.contains(bot)) {
      await event.message.channel.sendMessage(MessageBuilder(content: '.'));
      await event.message.delete();
    }

    // .v command
    if (content == '.v') {
      await event.message.channel.sendMessage(MessageBuilder(
        content:
            '### Thank you for your purchase! Please vouch in <#1371532842961604709>, and if you want to attach an image, blur the username that delivered the goods.',
      ));
      await event.message.delete();
    }

    // .pp command
    if (content == '.pp') {
      await event.message.channel.sendMessage(MessageBuilder(
        content:
            '## Please send your amount in EURO to http://paypal.me/Adm3w as Friends & Family. You must cover any fees.',
      ));
      await event.message.delete();
    }

    // .c command
    if (content.startsWith('.c')) {
      int skellies = 0;
      int money = 0;
      int elytras = 0;

      final args = content.substring(2).trim().split(RegExp(r'\s+'));
      for (final arg in args) {
        if (arg.isEmpty) continue;
        final lower = arg.toLowerCase();
        if (lower.startsWith('s')) {
          skellies = int.tryParse(lower.substring(1)) ?? 0;
        } else if (lower.startsWith('m')) {
          money = int.tryParse(lower.substring(1)) ?? 0;
        } else if (lower.startsWith('e')) {
          elytras = int.tryParse(lower.substring(1)) ?? 0;
        }
      }

      final skelliesPrice = 0.20;
      final moneyPrice = 0.20;
      final elytraPrice = 20.00;

      final total = (skellies * skelliesPrice) +
          (money * moneyPrice) +
          (elytras * elytraPrice);

      final reply = '€${total.toStringAsFixed(2)}';
      await event.message.channel.sendMessage(MessageBuilder(content: reply));
      return;
    }

    // ✅ NEW: .n @user command
    if (content.startsWith('.n')) {
      final mentionedUsers = event.message.mentions;

      if (mentionedUsers.isEmpty) {
        await event.message.channel.sendMessage(MessageBuilder(
          content: '❌ Please mention a user to notify.',
        ));
        return;
      }

      for (final user in mentionedUsers) {
        try {
          final dm = await client.channels.createDm(user.id);
          await dm.sendMessage(MessageBuilder(
            content: 'Please check your ticket in DonutShop.',
          ));

          await event.message.channel.sendMessage(MessageBuilder(
            content: '✅ Notified ${MentionUtils.mentionUser(user.id)}',
          ));
        } catch (e) {
          await event.message.channel.sendMessage(MessageBuilder(
            content:
                '❌ Failed to notify ${MentionUtils.mentionUser(user.id)}.',
          ));
        }
      }

      await event.message.delete();
      return;
    }
  });

  // Auto message when a new text channel is created
  client.onChannelCreate.listen((event) async {
    if (event.channel is TextChannel) {
      final textChannel = event.channel as TextChannel;
      try {
        await textChannel.sendMessage(MessageBuilder(
          content:
              "## Hello! Please describe your request and wait for a response. Make sure to ping us too. The current average response time is 1–10 minutes.",
        ));
        print("👋 Sent Hi in a new text channel with ID: ${textChannel.id}");
      } catch (e) {
        print("❌ Failed to send message in new channel: ${textChannel.id} - $e");
      }
    }
  });

  // Keep alive server
  var port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  var server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print("🌍 Fake server running on port $port");
  await for (var request in server) {
    request.response
      ..write("Bot is running!")
      ..close();
  }
}
