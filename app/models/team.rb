class Team < User
  has_many :team_users
  has_many :users, through: :team_users

  has_many :topics

  attr_accessor :owner_id
  after_create do
    self.team_users.create(user_id: owner_id, role: :owner, status: :accepted) if self.owner_id.present?
  end

  def user_ids
    @user_ids ||= self.users.pluck(:id)
  end

  def password_required?
    false
  end

  def owner?(user)
    self.team_users.accepted.exists?(role: :owner, user_id: user.id)
  end

  def team_admin
    if self.team_users.owner.exists?
      (User.find_by! id:self.team_users.owner.first.user_id)
    end
  end

  def member?(user)
    self.team_users.accepted.exists?(user_id: user.id)
  end

  def ready_to_be_member?(user)
    self.team_users.pendding.exists?(user_id: user.id) or self.team_users.pendding_owner_approved.exists?(user_id: user.id)
  end

  def pendding_status?(user)
    self.team_users.pendding.exists?(user_id: user.id)
  end

  def pendding_owner_approved_status?(user)
    self.team_users.pendding_owner_approved.exists?(user_id: user.id)
  end

  def get_team_user(user)
    if pendding_status?(user)
      self.team_users.pendding.find_by_user_id user
    end
  end
end