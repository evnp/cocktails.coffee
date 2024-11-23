# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Cc.Repo.insert!(%Cc.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Cc.Accounts
alias Cc.Chat.Room
alias Cc.Chat.Message
alias Cc.Repo

names = [
  "Aragorn",
  "Boromir",
  "Elrond",
  "Frodo",
  "Gandalf",
  "Gimli",
  "Legolas"
]

pw = "TheFellowship"

for name <- names do
  email = (name |> String.downcase()) <> "@fellowship.me"
  Accounts.register_user(%{email: email, password: pw, password_confirmation: pw})
end

elrond = Accounts.get_user_by_email("elrond@fellowship.me")
aragorn = Accounts.get_user_by_email("aragorn@fellowship.me")
boromir = Accounts.get_user_by_email("boromir@fellowship.me")

shire = Repo.insert!(%Room{name: "the-shire", topic: "Bilbo's eleventy-first birthday party"})

council = Repo.insert!(%Room{name: "council-of-elrond", topic: "What to do with this ring?"})

for {user, message} <- [
      {elrond,
       "Strangers from distant lands, friends of old. You have been summoned here to answer the threat of Mordor. Middle-Earth stands upon the brink of destruction. None can escape it. You will unite or you will fall. Each race is bound to this fate–this one doom."},
      {elrond, "Bring forth the Ring, Frodo."},
      {boromir, "So it is true…"},
      {boromir,
       "It is a gift. A gift to the foes of Mordor. Why not use this Ring? Long has my father, the Steward of Gondor, kept the forces of Mordor at bay. By the blood of our people are your lands kept safe! Give Gondor the weapon of the Enemy. Let us use it against him!"},
      {aragorn,
       "You cannot wield it! None of us can. The One Ring answers to Sauron alone. It has no other master."},
      {boromir, "And what would a ranger know of this matter?"}
    ] do
  Repo.insert!(%Message{user: user, room: council, body: message})
end
