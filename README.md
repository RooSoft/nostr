# nostr

![nostr](https://raw.githubusercontent.com/RooSoft/nostr/main/guides/assets/images/nostr.jpeg)&nbsp;&nbsp;
![Elixir](https://raw.githubusercontent.com/RooSoft/nostr/main/guides/assets/images/elixir-with-name.svg)

Communicate with any participant, be it relays or clients, with elixir 

## Installation

As of now, this project needs [rust](https://www.rust-lang.org) to compile. We're in the process of getting 
rid of that dependency despite rust still being use dunder the covers, thanks to 
[rustler_precompiled](https://github.com/philss/rustler_precompiled).

```elixir
def deps do
  [
    {:nostr,  git: "https://github.com/RooSoft/nostr.git"}
  ]
end
```

## Create a private key

```bash
iex -S mix
```

```elixir
K256.Schnorr.generate_random_signing_key
```

## Use the example app

In the lib/examples, there is a NostrApp ready to be used. It connects to a relay and
retrieves your own notes and stuff. The easiest way to use it is to create a `.iex.local.exs`
file and paste that in

```elixir
relay = "wss://relay.nostr.pro" ## here's a list of relays: https://nostr-registry.netlify.app
private_key = <<>> ### here goes your private key

NostrApp.start_link(relay, private_key)
```

and start iex

```bash
iex -S mix
```

## Now what?

You'll receive past and live events into the console, and are now able to send messages with
that identity.

```elixir
NostrApp.send("aren't you entertained?")
```
