# eg25-autorestart

A systemd timer, service and script to autorestart your EG25 modem when it disappears.

## Usage

To enable it, simply run:

```
systemctl enable --now eg25-autorestart.timer
```

To do a single run yourself (when you know the modem is down, but don't want to wait for timer activation):

```
systemctl start eg25-autorestart.service
```

**When you're modifying your modem (such as flashing a new firmware), it is important to disable this!**

To do so, run:

```
systemctl disable --now eg25-autorestart.{service,timer}
```

And use the instructions to enable it again once you're done.
