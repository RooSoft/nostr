# nostr

![nostr](https://raw.githubusercontent.com/RooSoft/nostr/main/guides/assets/images/nostr.jpeg)&nbsp;&nbsp;
![Elixir](https://raw.githubusercontent.com/RooSoft/nostr/main/guides/assets/images/elixir-with-name.svg)

Communicate with any participant, be it relays or clients, with elixir 

## Installation

```elixir
def deps do
  [
    {:nostr, "~> 0.1.0"}
  ]
end
```

## Create a private key

```bash
iex -S mix
```

```elixir
Nostr.Keys.PrivateKey.create()
```

## Use the example app

In the lib/examples, there is a NostrApp ready to be used. It connects to a relay and
retrieves your own notes and stuff. The easiest way to use it is to create a `.iex.local.exs`
file and paste that in

```elixir
relays = [
  "wss://relay.nostr.bg",
  "wss://relay.nostr.pro"
]

private_key = Nostr.Keys.PrivateKey.create

NostrApp.start_link(relays, private_key)
```

and start iex

```bash
iex -S mix
```

## Now what?

```elixir
Nostr.Keys.PublicKey.from_private(private_key)
|> NostrApp.timeline()
```

You'll receive past and live events from all your followed contacts into the console, 
and are now able to send messages with that identity.

```elixir
NostrApp.send("aren't you entertained?")
```
