# Dankirk - minecraft-irc-bot 
Legacy mIRC script for "Dankirk" minecraft bot on IRC. 
Answers FAQs, records stats, tells "fun facts" based on stats, scans for and reports compromised accounts, tells jokes and does sing-alongs.

This is an old project from circa 2014 and is not maintained anymore. This is here for legacy purposes only. 


# Usage and development info
Some old usage and development information is available at fCraft forums

http://forum.fcraft.net/viewtopic.php?f=2&t=22



# How do I get set up?

1. Install mIRC and MySql server.
2. Import ```DB structure.sql``` to MySql
3. Copy/rename ```Ma-template.ini``` as ```MA.ini```
4. Copy/rename ```website/settings-template.php``` as ```website/settings.php```
5. Edit ```MA.ini``` and ```website/settings.php``` to reflect your environment.
6. Load scripts (the .mrc files) in mIRC
    
       /load -rs mmysql.mrc
       /load -rs Themesongs.mrc
       /load -rs GoogleTranslate.mrc
       /load -rs "minecraft autoreply db.mrc"
7. (Optional) The admin panel in "website" folder requires Apache/nginx and PHP
   Setup webserver to serve contents of "website" folder.
8. Setup the bot for an IRC channel

       /ma.CreateNewServer <fCraft bridge bot's nickname on the channel>
       
       
# Command guide
    /ma.passreset <channel> echoes a link for admin panel password reset for the channel
    /ma.tell <msg> broadcasts a message to all channels the bot is registered to
    /ma.mergeop <old op> <new server id> <new op> Merges statistics of old op to a new op. (In case they changed names)
    /ma.removeserver unregisters the server/channel (all data is lost)
    /ma.hackcheck <nickname/player> Checks if a player is reported compromised on haveibeenpwned.com
    
# ICHG.mrc (Griefer forum scanning)

Old script (most likely not working anymore) to scan various griefer forums for nicknames to blacklist.
Blacklisted names are matched to joining player names on Minecraft server / IRC channel and reported if a match is found.

Supposedly you can still try running it after configuring ```MA.ini``` for the settings:

    /load -rs ICHG.mrc 
    /icanhasgrief 
