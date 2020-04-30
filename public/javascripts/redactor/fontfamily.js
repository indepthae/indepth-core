if (!RedactorPlugins) var RedactorPlugins = {};

RedactorPlugins.fontfamily = {
	init: function ()
	{
		var fonts = [ 'Lato', 'Playball', 'Courgette', 'Lora'];
		var that = this;
		var dropdown = {};

		j.each(fonts, function(i, s)
		{
			dropdown['s' + i] = { title: s, callback: function() { that.setFontfamily(s); }};
		});

		dropdown['remove'] = { title: 'Remove font', callback: function() { that.resetFontfamily(); }};

		this.buttonAdd('fontfamily', 'Change font family', false, dropdown);
	},
	setFontfamily: function (value)
	{
		this.inlineSetStyle('font-family', value);
	},
	resetFontfamily: function()
	{
		this.inlineRemoveStyle('font-family');
	}
};
