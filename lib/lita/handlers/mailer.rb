require 'json'
require 'mail'

module Lita
  module Handlers
    class Mailer < Handler

      route(/^mail new/, :mail, command: true, help: { "mail new" => "Start building an email" })
      route(/^mail list.+/, :list, command: true)
      route(/^mail subj.+/, :subj, command: true)
      route(/^mail body.+/, :body, command: true)
      route(/^mail send.+/, :send, command: true)
      route(/^mail check.+/, :check, command: true, help: { "mail check KEY" => "Check status of an email" })

      def mail(resp)
        key = string_gen

        resp.reply_privately "KEY: `#{key}`"
        resp.reply_privately "Next Step: lita mail list #{key} asdf@example.com"

        redis.set(key, new_email)

        after(600) do # after 10 minutes, invalidate key
          email = JSON.parse(redis.get(key))
          if email["valid"]
            redis.del(key)
            resp.reply_privately "FYI: Email with key '#{key}' now invalid."
          else
            # Just to make sure that we clean this up
            redis.del(key)
          end
        end
      end

      def list(resp)
        args = resp.args.dup
        args.shift # get rid of "list"

        key = args.shift # pop off the key

        email = JSON.parse(redis.get(key))

        email["list"] = args # everything else is the body
        redis.set(key, email.to_json)

        resp.reply_privately "Mail list for #{key} set to: \n #{blockify(email["list"].join("\n"))}"
        resp.reply_privately "Next Step: lita mail subj #{key} SUBJ"
      end

      def subj(resp)
        args = resp.args.dup
        args.shift # get rid of "subj"

        key = args.shift # pop off the key

        email = JSON.parse(redis.get(key))

        email["subj"] = args # everything else is the body
        redis.set(key, email.to_json)

        resp.reply_privately "Subject for `#{key}` set to: \n #{blockify(email["subj"].join(" "))}"
        resp.reply_privately "Next Step: lita mail body #{key} STUFF"
      end

      def body(resp)
        args = resp.args.dup
        args.shift # get rid of "body"

        key = args.shift # pop off the key

        email = JSON.parse(redis.get(key))

        email["body"] = args # everything else is the body
        redis.set(key, email.to_json)

        resp.reply_privately "Body for `#{key}` set to: \n #{blockify(email["body"].join(" "))}"
        resp.reply_privately "Next Step: lita mail send #{key}"
      end

      def send(resp)
        args = resp.args.dup
        args.shift # get rid of "send"

        key = args.shift # pop off the key

        email = JSON.parse(redis.get(key))

        email["list"].each do |recipent|
          Mail.deliver do
            from     'lita@peopleadmin.com'
            to       recipent
            subject  email["subj"].join(" ")
            body     email["body"].join(" ") + "\n\nSent by your friendly Lita Bot"
          end
        end
      end

      def check(resp)
        args = resp.args.dup
        args.shift # get rid of "check"

        key = args.shift # pop off the key

        email = JSON.parse(redis.get(key))

        out = String.new
        out += email["valid"] ? "Email valid... yes\n" : "Email valid... FALSE\n"
        out += email["list"]  ? "Email list.... yes\n" : "Email list.... FALSE\n"
        out += email["subj"]  ? "Email subj.... yes\n" : "Email subj.... FALSE\n"
        out += email["body"]  ? "Email body.... yes\n" : "Email body.... FALSE\n"

        resp.reply_privately blockify(out)
      end

      private

      def string_gen
        ('a'..'z').to_a.shuffle[0,8].join
      end

      def blockify(text)
        "```\n#{text}\n```"
      end

      def new_email
        {
          valid: true,
          list: nil,
          subj: nil,
          body: nil,
          sender: nil
        }.to_json
      end

    end

    Lita.register_handler(Mailer)
  end
end
