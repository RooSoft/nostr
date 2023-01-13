# nostr

![nostr](https://raw.githubusercontent.com/RooSoft/nostr/main/guides/assets/images/nostr.jpeg)&nbsp;&nbsp;
![Elixir](https://raw.githubusercontent.com/RooSoft/nostr/main/guides/assets/images/elixir-with-name.svg)

Communicate with any participant, be it relays or clients, with elixir 

**DISCLAMER** This library is in the process of being built in the wild. It should at the moment be considered
alpha quality. Function names and what they return will most probably be improved in the near future, so
don't expect to write production code on top of it just yet. This is for education purposes only.

The current goal is to get feature complete with the most common NIPs, and will then be refined so it's
as easy to use as can be.

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

### Subscribe to a timeline

```elixir
Nostr.Keys.PublicKey.from_private(private_key)
|> NostrApp.timeline()
```

You'll receive past and live events from all your followed contacts into the console, 
and are now able to send messages with that identity.


### Send a message

```elixir
NostrApp.send("aren't you entertained?")
```

### Follow someone

This is a bit rough around the edges still, but will be simplified soon

```elixir
"npub1s5yq6wadwrxde4lhfs56gn64hwzuhnfa6r9mj476r5s4hkunzgzqrs6q7z"
|> Nostr.Keys.PublicKey.from_npub!()
|> NostrApp.follow()
```

### See who someone is currently following

Could be yourself or anybody...

```elixir
"npub1s5yq6wadwrxde4lhfs56gn64hwzuhnfa6r9mj476r5s4hkunzgzqrs6q7z"
|> Nostr.Keys.PublicKey.from_npub!()
|> NostrApp.contacts 
```