class ZonePolicy < ApplicationPolicy
  def show?
    true
  end

  def update?
    user.admin? || user_is_owner?
  end

  def edit? = update?

  def view_ddns_secrets?
    user_is_owner?
  end

  def approve?
    user.admin? && !record.approved?
  end

  def unapprove?
    user.admin? && record.approved?
  end

  def enable?
    update? && record.disabled?
  end

  def disable?
    update? && record.enabled?
  end
end
