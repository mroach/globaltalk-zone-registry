class ZonePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def new?
    user.onboarded?
  end

  def update?
    user.admin? || user_is_owner?
  end

  def edit? = update?

  def destroy?
    update?
  end
end
