import discord
import sqlite3
from discord.ext import tasks

intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)
grabbed = {}

# On Message Sent
@client.event
async def on_message(message):
    
    # Make sure the bot doesn't respond to itself.
    if message and message.author == client.user:
        return
    
    # Info command
    if message.content.startswith("!info"):
        await message.channel.send("Commands are prefixed with \"!\".\r\n \"fight <UserName>,<CodeName>,<Code>\" to add a Navi Setup.\r\n \"left <value>\", \"right <value>\", or \"random <value>\" to bet on combatants at the start of each battle with Zenny.\r\n \"balance\" to see how much Zenny you have.\r\n \"banlist\" to check the current Chip ban list.\r\n Navi Setups can be generated here: https://therockmanexezone.com/ncgen/")
        return
    
    # Other Commands
    if message.content.startswith("!banned") or message.content.startswith("!banlist") or message.content.startswith("!turncount") or message.content.startswith("!balance") or message.content.startswith("!left") or message.content.startswith("!right") or message.content.startswith("!random") or message.content.startswith("!fight"):
        con = sqlite3.connect("./db/database.db")
        db = con.cursor()
        res = db.execute(f"INSERT INTO commands VALUES (\"{message.author}\", \"{message.author.id}\",\"{message.content}\",NULL)")
        con.commit()
        con.close()
        return

# Task Loop for Message Search from Emulator
@tasks.loop(seconds=0.016)
async def read_cmd_results():
    con = sqlite3.connect("./db/database.db")
    db = con.cursor()
    results = db.execute(f"SELECT * FROM commands WHERE result = 0 OR result IS NOT NULL").fetchone()
    if results is None or results[3] == 0 or len(results[3]) < 1:
        return
    usr = await client.fetch_user(results[1])
    await usr.send(results[3])
    db.execute(f"DELETE FROM commands WHERE result = \"{results[3]}\" AND user = \"{results[0]}\" and cmd = \"{results[2]}\" and userid = \"{results[1]}\"")
    con.commit()
    con.close()
    return

# On Bot Ready
@client.event
async def on_ready():
    print("Hello! BCCPlaysBCC is active. Use \"!info\" for more information.")
    read_cmd_results.start()

client.run("YOUR_DISCORD_BOT_TOKEN")