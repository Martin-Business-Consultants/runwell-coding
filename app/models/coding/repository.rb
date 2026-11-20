module Coding
  # A git repository linked to a client, a piece of work or a task. Any remote works (GitHub,
  # GitLab, Bitbucket, your own); GitHub ones also get pull requests, checks, deploys and issues
  # once Settings > Code is connected. A task with no repo of its own uses its work's, and a piece
  # of work its client's, so most repos are linked once, high up. Never holds secrets: the setup
  # notes say where they live.
  class Repository < ::ApplicationRecord
    self.table_name = "coding_repositories"

    LINKABLE_TYPES = %w[Client Work Task].freeze
    GITHUB = %r{\A(?:https?://github\.com/|git@github\.com:|ssh://git@github\.com/)([\w.-]+/[\w.-]+?)(?:\.git)?/?\z}

    belongs_to :linkable, polymorphic: true
    belongs_to :work, class_name: "::Work", optional: true
    belongs_to :client, class_name: "::Client"
    belongs_to :added_by, class_name: "::User", optional: true
    has_many :branches, dependent: :destroy
    has_many :deploys, dependent: :destroy
    has_many :commits, dependent: :destroy
    has_many :issues, dependent: :destroy
    has_many :collaborators, dependent: :destroy

    normalizes :url, :staging_url, :production_url, :path, with: ->(value) { value.to_s.strip.presence }
    normalizes :default_branch, with: ->(value) { value.to_s.strip.presence || "main" }

    validates :linkable_type, inclusion: { in: LINKABLE_TYPES }
    validates :url, presence: true, format: { with: %r{\A(?:https?://|ssh://|git@)\S+\z}, message: "should be a git remote, like https://github.com/you/site or git@github.com:you/site.git" }
    validates :url, uniqueness: { scope: %i[linkable_type linkable_id], message: "is already linked here" }
    validates :staging_url, :production_url, format: { with: %r{\Ahttps?://\S+\z}, message: "should start with https://" }, allow_nil: true

    before_validation :fill_in_context
    before_validation { self.full_name = url.to_s[GITHUB, 1] }

    scope :github, -> { where.not(full_name: nil) }
    scope :ordered, -> { order(:created_at) }

    class << self
      # The repos a record works in: its own, or the nearest ones above it (a task's work's, then
      # its client's). An Array, empty when there are none.
      def for(record)
        owners = candidates(record)
        return [] if owners.empty?

        # One query for every level, then the nearest level that has any.
        linked = owners.map { |owner| where(linkable: owner) }.reduce(:or).ordered.to_a
        owners.lazy.map { |owner| linked.select { it.linkable_type == owner.class.name && it.linkable_id == owner.id } }.find(&:any?) || []
      end

      # Where the repos in .for came from, or nil when there are none.
      def source_for(record) = candidates(record).find { where(linkable: it).exists? }

      # Repos linked from a section go to its work.
      def linkable_for(record)
        LINKABLE_TYPES.include?(record.class.name) ? record : record.try(:work) || record.try(:client)
      end

      def find_by_full_name(name) = github.where("lower(full_name) = ?", name.to_s.downcase)

      private
        def candidates(record)
          case record
          when ::Task then [ record, record.work, record.client ].compact
          when ::Work then [ record, record.client ]
          when ::Client then [ record ]
          else []
          end
        end
    end

    def github? = full_name.present?
    def name = full_name || url.split(%r{[/:]}).last.to_s.delete_suffix(".git")
    def label = name
    def web_url = github? ? "https://github.com/#{full_name}" : url.sub(/\Agit@([^:]+):/, 'https://\1/').delete_suffix(".git")

    def linked_label
      case linkable
      when ::Task, ::Work then linkable.title
      when ::Client then linkable.name
      end
    end

    # Work whose timeline hears about this repo: the piece it's on, or every open one of its
    # client when it's linked to the client.
    def works
      work ? [ work ] : client.works.open.to_a
    end

    # Whoever linked it (or their agent), or someone who may delete records.
    def deletable_by?(user) = (added_by && added_by.person == user.person) || user.can?(:delete_records)

    def latest_deploys = deploys.where(id: deploys.group(:environment).select("max(id)")).order(:environment)

    private
      def fill_in_context
        case linkable
        when ::Task
          self.work = linkable.work
          self.client_id = linkable.client_id
        when ::Work
          self.work = linkable
          self.client_id = linkable.client_id
        when ::Client
          self.work = nil
          self.client = linkable
        end
      end
  end
end
