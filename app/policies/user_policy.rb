class UserPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def edit?
    puts "checking if #{user.id} is #{record.id}"
    user.id == record.id
  end

  def update?
    user.id == record.id
  end
end
