# picklerick_store
I8C Hackaton 

## Use case

![img.png](images/img.png)


## Setup 

### Web server and web app

### Confluent

### Telegram
<b>Setting up Telegram to receive notifications</b><br/>
In order to use Telegram as a notification server, you need to create a bot.
Creating bots is wel documented in multiple blogs and tutorials so we won't go in to much detail
here.

After installing and login into telegram, search for the BotFather bot (note the blue checkmark)
![img_1.png](images/img_1.png)

Send it the message 
`/start`

And follow the new bot wizard by sending
`/newbot`

When your bot is created you should receive a message like the one below containing your access token.
With this token you can control your bot so don't just hand it out.
![img_2.png](images/img_2.png)\

From this point on you can interact with your bot. Search for your bot and send the start message and some random text 
(you need to do this in order to complete the following steps). 
![img_4.png](images/img_4.png)

Next open a browser and send a getUpdates call to your bot on the url
`https://api.telegram.org/bot<api_key>/getUpdates`

This will give you the following information
![img_3.png](images/img_3.png)

The obfuscted value is the id of the chat between the bot and myself (if someone else starts chatting 
with this bot they will receive a different chat id). This value and the api key will be required in confluenct.

