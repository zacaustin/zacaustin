# Zac Austin

## 😄 About
I’m currently the Head of Audio and Systems at [45 Productions](https://45productions.com.au/?utm_source=github&utm_medium=referral&utm_campaign=zacaustin), where I primarily work on live audio for school musical theatre in Sydney, Australia.

At [45 Productions](https://45productions.com.au/?utm_source=github&utm_medium=referral&utm_campaign=zacaustin), we develop a wide range of internal software, tools, interfaces, applications, and embedded devices. My primary language is Node.js (JavaScript), but I also work with C++, AVR C, Swift, and more.

If you're wondering why it seems like I don't do much, it's because most of my work and contributions are on private repositories. But I'm working on making more of my work available publically. Follow my profile to see when this eventually happens!

## 📫 Contact
If you’d like to get in touch — whether to ask about this repository, discuss an upcoming project, or anything else — feel free to reach out at [hello@zacaustin.com.au](mailto:hello@zacaustin.com.au).

## 🤔 What's in this repository?
This repository ([zacaustin/zacaustin](https://github.com/zacaustin/zacaustin)) contains several resources, tools, scripts and utilities that I used in my daily work.

### Server Setup Scripts
The following command will download and run my setup script for cloud server deployments.

```bash
curl -fsSL "https://raw.githubusercontent.com/zacaustin/zacaustin/main/scripts/setup.sh" -o setup.sh
sudo bash setup.sh
```

The script works by firstly running a handful of commands on the root user, then prompts you for a non-root username to create.

After that user is created, it pulls the second part of the script from this repo, and sets that up to run as the new non-root user on next boot. It then reboots the machine.

The second part then proceeds to setup the server as configured in part one. It even cleans up after itself!

### NodeJS Based Project Generator
The generator I created to automate repetitive setup processes for my software development projects.

Right now, it only generates package.json files for Node.js projects, but I plan to expand it with more features over time. Eventually, it will use EJS templates to dynamically generate file contents, keeping everything modular and reducing boilerplate.

If you’re interested, feel free to try it out!

I plan to constantly expand this repository to include various tools, scripts, and utilities that I use in my daily work. As a byproduct of making these resources easily accessible for myself, you also get a sneak peek at how my brain works!

Enjoy!
