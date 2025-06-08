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

  // Message handling
  client.onMessageCreate.listen((event) async {
    final content = event.message.content.trim();

    // Only allow commands from a specific user (ID: 1300544825371656202)
    if (event.message.author.id.toString() != '1300544825371656202') {
      return;
    }

    // Respond to bot mention
    if (event.mentions.contains(bot)) {
      await event.message.channel.sendMessage(MessageBuilder(content: '.'));
      await event.message.delete();
    }

    // Respond to .v command
    if (content == '.v') {
      await event.message.channel.sendMessage(MessageBuilder(
        content:
            '### Thank you for your purchase! Please vouch in <#1371532842961604709>, and if you want to attach an image, blur the username that delivered the goods.',
      ));
      await event.message.delete();
    }

    // Respond to .pp command
    if (content == '.pp') {
      await event.message.channel.sendMessage(MessageBuilder(
        content:
            '## Please send your amount in EURO to http://paypal.me/LauraBaune175 as Friends & Family. You must cover any fees.',
      ));
      await event.message.delete();
    }

    // Respond to .c command for calculation
    if (content.startsWith('.c')) {
      // Remove '.c' and trim
      final args = content.substring(2).trim().split(' ');

      int skellies = 0;
      int moneyMillions = 0;
      int elytras = 0;

      // Parse the arguments like s1, m5, e1
      for (var arg in args) {
        if (arg.startsWith('s')) {
          skellies = int.tryParse(arg.substring(1)) ?? 0;
        } else if (arg.startsWith('m')) {
          moneyMillions = int.tryParse(arg.substring(1)) ?? 0;
        } else if (arg.startsWith('e')) {
          elytras = int.tryParse(arg.substring(1)) ?? 0;
        }
      }

      // Calculate total cost
      double total = 0;
      total += skellies * 0.20;
      total += moneyMillions * 0.20;
      total += elytras * 15.0;

      // Format the output
      final result = StringBuffer();
      result.writeln('Calculation results:');
      if (skellies > 0) {
        result.writeln(
            '- Skellies: $skellies x \$0.20 = \$${(skellies * 0.20).toStringAsFixed(2)}');
      }
      if (moneyMillions > 0) {
        result.writeln(
            '- Money (millions): $moneyMillions x \$0.20 = \$${(moneyMillions * 0.20).toStringAsFixed(2)}');
      }
      if (elytras > 0) {
        result.writeln(
            '- Elytras: $elytras x \$15.00 = \$${(elytras * 15.0).toStringAsFixed(2)}');
      }
      result.writeln('**Total: \$${total.toStringAsFixed(2)}**');

      await event.message.channel.sendMessage(MessageBuilder(content: result.toString()));
      await event.message.delete();
    }
  });

  // Auto message when a new text channel is created
  client.onChannelCreate.listen((event) async {
    if (event.channel is TextChannel) {
      final textChannel = event.channel as TextChannel;
      try {
        await textChannel.sendMessage(MessageBuilder(content:
            "## Hello! Please describe your request and wait for a response. Make sure to ping us too. The current average response time is 1–10 minutes."));
        print("👋 Sent Hi in a new text channel with ID: ${textChannel.id}");
      } catch (e) {
        print(
            "❌ Failed to send message in new channel with ID: ${textChannel.id} - $e");
      }
    }
  });

  // Fake web server to keep bot alive on platforms like Render
  var port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  var server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print("🌍 Fake server running on port $port");
  await for (var request in server) {
    request.response
      ..write("Bot is running!")
      ..close();
  }
}
