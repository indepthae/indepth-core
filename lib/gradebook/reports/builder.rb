module Gradebook
  module Reports
    class Builder
      attr_accessor :report, :template, :component

      def self.build_report (report)
        builder = Builder.new(report)
        builder.build
      end

      def initialize (report)
        @report = report
        @template = report.report_template
        @component = report.report_component
      end

      def build
        pdf_file = render_pdf
        store_pdf(pdf_file)
      end

      def render_pdf
        Renderer.render(component, template, report.assessment_plan.id,report)
      end

      def store_pdf (pdf_file)
        report.store_pdf(pdf_file)
      end

    end
  end
end