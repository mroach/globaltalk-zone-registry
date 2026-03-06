class ApplicationPolicy < ActionPolicy::Base
  def show?
    true
  end

  def new?
    allow! if user.admin?
  end

  def create? = new?

  def update?
    allow! if user.admin?
  end

  def edit? = update?

  def destroy?
    allow! if user.admin?
  end

  private

  def user_is_owner?
    user.id == record.user_id
  end
end
