#!/bin/xonsh

print("Starting XBot")

# Get data stored
$TOKEN  = $(cat "TOKEN.txt")
$GUILDS = list(filter(None, $(cat "GUILDS.txt").splitlines()))
$USERS  = list(filter(None, $(cat "USERS.txt").splitlines()))

# Import modules
print("Importing modules..")
import discord, io

# Init client
print("Initializing client..")
client = discord.Client()

# On ready
@client.event
async def on_ready():
	print(f"Connected as '{client.user}'")
	print(f"Listening servers: {', '.join($GUILDS)}")
	print(f"Listening users: {', '.join($USERS)}")


# On message
@client.event
async def on_message(message):
	# Ignore messages from not approved users or on not approved servers
	if str(message.author.id) not in $USERS or str(message.guild.id) not in $GUILDS:
		return
	
	# Run command
	result = !(@(message.content.split(' ')))

	# Extract useful data
	args         = f'```{result.args}```'
	alias        = f'```{result.alias}```'
	executed_cmd = f'```{result.executed_cmd}```'
	returncode   = f'```{result.returncode}```'
	pid			 = f'```{result.pid}```'
	output       = result.output
	errors       = result.errors

	# Add output 
	file_out = None
	if not output:
		output = '```No output```'
	elif len(output) > 1024:
		# Discord limitations
		output = '```Output is too long (>1024), see attached file```'
		file_out = discord.File(io.BytesIO(result.output.encode('utf-8')), filename = 'output.txt')
	else:
		output = f'```{output}```'

	# Add errors
	file_err = None
	if errors is None:
		errors = '```No errors```'
	elif len(errors) > 1024:
		# Discord limitations
		errors = '```Errors is too long (>1024), see attached file```'
		file_err = discord.File(io.BytesIO(result.errors.encode('utf-8')), filename = 'errors.txt')
	else:
		errors = f'```{errors}```'

	# Create embed
	# You can easily customize it by changing the values below
	$TITLE        = f'Command executed {"successfully" if result.returncode == 0 else "unsuccessfully"}'
	$DESCRIPTION  = f'Command `{message.content}` from user `{message.author.name}` execution report'
	$COLOR        = discord.Color.green() if result.returncode == 0 else discord.Color.red()

	await message.channel.send(embed=\
		discord.Embed(title=$TITLE, description=$DESCRIPTION, color=$COLOR)\
		.add_field(name = 'Command', value = args, inline = True)\
		.add_field(name = 'Aliases', value = alias, inline = True)\
		.add_field(name = 'Executed command', value = executed_cmd, inline = False)\
		.add_field(name = 'Process ID', value = pid, inline = True)\
		.add_field(name = 'Exit status', value = returncode, inline = True)\
		.add_field(name = 'Output', value = output, inline = False)\
		.add_field(name = 'Errors', value = errors, inline = False))

	# Send embed
	if file_out:
		await message.channel.send(file=file_out)
	if file_err:
		await message.channel.send(file=file_err)

# Run client
print("Starting client..")
client.run($TOKEN)
