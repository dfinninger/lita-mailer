module Lita
  module Handlers
    class Mailer < Handler

      route(/^mail\s+/, :mail, command: true, help: {
        "mail ADDR TEXT" => "Send an email to ADDR with the body TEXT"
        })

      def mail(resp)
        resp.reply "```Your message would be to: #{resp.args.shift}\nMessage: #{resp.args}```"
      end

    end

    Lita.register_handler(Mailer)
  end
end
