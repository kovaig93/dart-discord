import 'dart:io';
import 'package:nyxx/nyxx.dart';

void main() async {
  final token = Platform.environment['TOKEN'] ?? '';

  final client = await Nyxx.connectGateway(
    token,
    GatewayIntents.all | GatewayIntents.messageContent,
  );

  final bot = await client.users.fetchCurrentUser();
  print("✅ Bot is online as ${bot.username}");

  // Register slash command on ready
  client.onReady.listen((_) async {
    final commands = await client.interactions.fetchGlobalCommands();

    if (!commands.any((cmd) => cmd.name == 'calc')) {
      await client.interactions.createGlobalCommand(ApplicationCommandBuilder(
        name: 'calc',
        description: 'Calculate total price',
        options: [
          CommandOptionBuilder(
            type: CommandOptionType.integer,
            name: 'skellies',
            description: 'Amount of skellies',
            required: true,
          ),
          CommandOptionBuilder(
            type: CommandOptionType.integer,
            name: 'money',
            description: 'Amount of money (in millions)',
            required: true,
          ),
          CommandOptionBuilder(
            type: CommandOptionType.integer,
            name: 'elytras',
            description: 'Amount of elytras',
            required: true,
          ),
        ],
      ));
      print('✅ Slash command /calc registered');
    }
  });

  // Slash command handler
  client.onInteractionCreate.listen((event) async {
    if (event is! IApplicationCommandInteraction) return;
    if (event.command.name != 'calc') return;

    final skellies = event.command.getInt('skellies')!;
    final money = event.command.getInt('money')!;
    final elytras = event.command.getInt('elytras')!;

    final total = skellies * 0.20 + money * 0.20 + elytras * 15.00;

    await event.respond(MessageBuilder(
      content: '''
### 💰 Calculation
- Skellies: $skellies × \$0.20
- Money: ${money}M × \$0.20
- Elytras: $elytras × \$15.00

**Total: \$${total.toStringAsFixed(2)}**
''',
    ));
  });

  // Message create handler
  client.onMessageCreate.listen((event) async {
    final content = event.message.content.trim();

    // Only allow commands from a specific user (ID: 1300544825371656202)
    if (event.message.author.id.toString() != '1300544825371656202') return;

    if (event.mentions.contains(bot)) {
      await event.message.channel.sendMessage(MessageBuilder(content: '.'));
      await event.message.delete();
    }

    if (content == '.v') {
      await event.message.channel.sendMessage(MessageBuilder(
        content: '### Thank you for your purchase! Please vouch in <#1371532842961604709>, and if you want to attach an image, blur the username that delivered the goods.',
      ));
      await event.message.delete();
    }

    if (content == '.pp') {
      await event.message.channel.sendMessage(MessageBuilder(
        content: '## Please send your amount in EURO to http://paypal.me/LauraBaune175 as Friends & Family. You must cover any fees.',
      ));
      await event.message.delete();
    }
  });

  // Send message in new text channel
  client.onChannelCreate.listen((event) async {
    if (event.channel is TextChannel) {
      final textChannel = event.channel as TextChannel;
      try {
        await textChannel.sendMessage(MessageBuilder(content:
          "## Hello! Please describe your request and wait for a response. Make sure to ping us too. The current average response time is 1–10 minutes."
        ));
        print("👋 Sent greeting in new channel: ${textChannel.id}");
      } catch (e) {
        print("❌ Failed to send message in new channel ${textChannel.id} - $e");
      }
    }
  });

  // Fake server to keep bot alive on platforms like Render
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print("🌐 Keep-alive server running on port $port");
  await for (final request in server) {
    request.response
      ..write("Bot is running!")
      ..close();
  }
}
