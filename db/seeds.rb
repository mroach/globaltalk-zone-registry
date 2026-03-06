# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

user1 = User.find_or_create_by!(email_address: "user1@example.com") do
  it.password = "password1"
  it.name = "User 1"
  it.time_zone = "Europe/Copenhagen"
  it.email_confirmed_at = Time.now
end
Zone.find_or_create_by!(name: "SuperZone") do
  it.assign_attributes(
    user: user1,
    network_ranges: 1440,
    about: "Lots of Windows machines",
    static_endpoint: "air.user1.example.com",
    approved_at: 1.minute.ago
  )
end

user2 = User.find_or_create_by!(email_address: "user2@example.com") do
  it.name = "User 2"
  it.password = "password2"
  it.time_zone = "Asia/Tokyo"
  it.email_confirmed_at = Time.now
end
Zone.find_or_create_by!(name: "Turtles") do
  it.assign_attributes(
    user: user2,
    network_ranges: 2940,
    about: "Lots of printers. You can *never* have too many.",
    ddns_subdomain: "turtles",
    ddns_ip: "24.34.153.229",
    approved_at: 1.minute.ago
  )
end

user3 = User.find_or_create_by!(email_address: "user3@example.com") do
  it.name = "Bob"
  it.password = "password3"
  it.time_zone = "Australia/Sydney"
end
Zone.find_or_create_by!(name: "Dunnynet") do
  it.assign_attributes(
    user: user3,
    network_ranges: 19680,
    about: "Linux!",
    static_endpoint: "dunnynet.example.com",
    approved_at: 1.minute.ago
  )
end
