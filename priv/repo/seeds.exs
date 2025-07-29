# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     QuranSrsPhoenix.Repo.insert!(%QuranSrsPhoenix.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Default permissions are defined in the Permissions context as module attributes
# This approach avoids foreign key issues and makes defaults easily accessible

IO.puts("Default permission configurations defined:")
IO.puts("- Parent: Can view, edit details, edit preferences")
IO.puts("- Teacher: Can view, edit details, edit preferences") 
IO.puts("- Student: Can view, edit preferences (hafiz can edit own)")
IO.puts("- Family: Can view only")

IO.puts("Seed data completed! Default permissions will be applied when users configure relationship permissions.")
