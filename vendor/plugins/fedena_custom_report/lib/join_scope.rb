module JoinScope
  def report_search(*args)
    opts=args.extract_options!
    join_params=opts.delete :join_params
    args << opts
    unless join_params.nil?
      with_scope(:find=>join_params) do
        search(*args)
      end
    else
      search(*args)
    end
  end
end
