import 'dart:io';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/nyxx_interactions.dart';

void main() async {
  final token = Platform.environment['TOKEN'] ?? '';

  final client = await Nyxx.connectGateway(
    token,
    GatewayIntents.all | GatewayIntents.messageContent,
  );

  final interactions = IInteractions.create(WebsocketInteractionBackend(client));

  // Register slash command
  interactions.registerSlashCommand(SlashCommandBuilder(
    'calc',
    'Calculate total price',
    [
      CommandOptionBuilder(CommandOptionType.integer, 'skellies', 'Amount of skellies', required: true),
      CommandOptionBuilder(CommandOptionType.integer, 'money', 'Amount of money (in millions)', required: true),
      CommandOptionBuilder(CommandOptionType.integer, 'elytras', 'Amount of elytras', required: true),
    ],
  )..registerHandler((event) async {
      final skellies = event.getArg('skellies').value as int;
      final money = event.getArg('money').value as int;
      final elytras = event.getArg('elytras').value as int;

      final total = skellies * 0.20 + money * 0.20 + elytras * 15;

      await event.respond(MessageBuilder(
        content: '### 💸 Calculation\n- Skellies: $skellies x \$0.20\n- Money: ${money}M x \$0.20\n- Elytras: $elytras x \$15.00\n\n**Total: \$${total.toStringAsFixed(2)}**',
      ));
  }));

  await interactions.syncCommands();

  print("✅ Bot is online");

  // Existing message + channel create handlers remain unchanged...
  client.onMessageCreate.listen((event) async {
    final content = event.message.content.trim();
    final bot = await client.users.fetchCurrentUser();

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

  client.onChannelCreate.listen((event) async {
    if (event.channel is TextChannel) {
      final textChannel = event.channel as TextChannel;
      try {
        await textChannel.sendMessage(MessageBuilder(content:
          "## Hello! Please describe your request and wait for a response. Make sure to ping us too. The current average response time is 1–10 minutes."
        ));
        print("👋 Sent Hi in a new text channel with ID: ${textChannel.id}");
      } catch (e) {
        print("❌ Failed to send message in new channel with ID: ${textChannel.id} - $e");
      }
    }
  });

  // Fake server
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print("🌍 Fake server running on port $port");
  await for (var request in server) {
    request.response
      ..write("Bot is running!")
      ..close();
  }
}
