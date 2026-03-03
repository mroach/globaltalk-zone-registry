# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

user = User.find_or_create_by!(email_address: "gtuser@example.com") do
  it.password = "letmein"
end

Zone.find_or_create_by!(ethertalk_zone_name: "The Danger Zone!") do
  it.assign_attributes(
    user:,
    localtalk_zone_name: "The Danger Zone!",
    ethertalk_zone_name: "The Danger Zone!",
    network_numbers: [12345],
    highlights: "Lots of test machines",
    comments: "No printing at night",
    public_endpoint: "127.0.0.1",
    approved_at: 1.minute.ago,
    ddns_subdomain: "danger-zone",
    ddns_password: "updateddns"
  )
end
