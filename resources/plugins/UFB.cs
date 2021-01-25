using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Windows.Forms;
using Viper.Scripting.Core.Classes;
using Viper.Scripting.Core.Interfaces;

namespace UsersPlugin {
	/// <summary>
	/// MMOViper Plugin Class
	/// </summary>
	class UsersFollowBot : Form, IPlugin {
		#region Script Internal Variables/Methods

		/// <summary>
		/// MMOViper instance
		/// </summary>
		IGame Bot;

		/// <summary>
		/// Leader this bot is currently following
		/// </summary>
		IMob Leader;

		/// <summary>
		/// Player this bot
		/// </summary>
		IPlayer Player;

		/// <summary>
		/// Cache of IMobs to be used by the Plugin
		/// Note: Entity cache should be Updated in NeedsToRun ONLY.
		/// </summary>
		List<IMob> cacheEntities = new List<IMob>();
		
		/// <summary>
		/// Indicates if the bot is currently fighting
		/// </summary>
		bool isFighting = false;

		/// <summary>
		/// List should contain players/bots this bot should follow. Add highest priority players/bots first.
		/// </summary>
		List<string> leaderList = new List<string>();

		/// <summary>
		/// String contains | seperated list of Leader names
		/// </summary>
		string leaderNames = "";

		/// <summary>
		/// String contains | seperated list of Leader GUIDs
		/// </summary>
		string leaderGUIDs = "";

		/// <summary>
		/// Bot should start following when the distance between the bot and the highest ranked player
		/// is less than maxRange and greater than minRange
		/// </summary>
		float minRange = 0;

		/// <summary>
		/// Bot should not attempt to follow any players who's distance is greater than maxRange
		/// </summary>
		float maxRange = 0;

		/// <summary>
		/// Distance the bot should target/face "Player"s
		/// </summary>
		float checkRange = 0;

		/// <summary>
		/// DateTime Bot last detected combat
		/// </summary>
		HighResTimer pauseForLootTime = new HighResTimer();

		/// <summary>
		/// Number of seconds to pause after combat to allow for looting
		/// </summary>
		int pauseForLootSeconds = 0;

		/// <summary>
		/// Indicates if this is the first execution of NeedsToRun
		/// </summary>
		bool isFirstRun = false;

		/// <summary>
		/// UsersFollowBot constructor
		/// </summary>
		public UsersFollowBot() {
			InitializeComponent();
		}

		#endregion

		#region Log Code Region

		/// <summary>
		/// The unique acronym this bot uses to seperate it from other bots in the log
		/// </summary>
		string botAcronym = "UFB";

		/// <summary>
		/// Level of detail to provide logging
		/// </summary>
		enum logLevel {
			None,
			Basic,
			Debug
		}
		logLevel _currentLogLevel = logLevel.None;

		/// <summary>
		/// Allow repeated messages
		/// </summary>
		bool canRepeat = false;

		/// <summary>
		/// Last log entry, used to prevent log entry repeats
		/// </summary>
		string _lastLogEntry = "";

		/// <summary>
		/// Current Indent Count, used to keep track of the number of indents currently being used.
		/// </summary>
		int _currentIndentCount = 0;

		/// <summary>
		/// Current Indent String, used to hold the current indent being used.
		/// </summary>
		string _currentIndentString = "";

		private void log(string text, logLevel level = logLevel.Basic, int indentBefore = 0, int indentAfter = 0) {
			// Check if logging is enabled
			if ((int)_currentLogLevel > 0 && (int)_currentLogLevel >= (int)level) {
				// Check if repeat messages is enabled
				if ((canRepeat || text != _lastLogEntry)) {
					Bot.Log.WriteLine(String.Format("{0} - {1}", botAcronym, text));
					_lastLogEntry = text;
				}
			}
		}

		#endregion

		#region Windows Form Designer Code Region

		/// <summary>
		/// Determines if the Bot has been properly Initialized
		/// </summary>
		bool isInitialized = false;

		/// <summary>
		/// Follow Bot GUI
		/// </summary>
		private System.Windows.Forms.Panel PluginPanel;
		private System.Windows.Forms.GroupBox Leader_GroupBox;
		private System.Windows.Forms.ToolTip Leader_Tooltip;
		private System.Windows.Forms.ListBox Leader_ListBox;
		private System.Windows.Forms.Button Remove_Button;
		private System.Windows.Forms.Button Add_Button;
		private System.Windows.Forms.ToolTip Add_Button_Tooltip;
		private System.Windows.Forms.GroupBox MinRange_GroupBox;
		private System.Windows.Forms.ToolTip MinRange_Tooltip;
		private System.Windows.Forms.NumericUpDown MinRange_UpDown;
		private System.Windows.Forms.GroupBox MaxRange_GroupBox;
		private System.Windows.Forms.ToolTip MaxRange_Tooltip;
		private System.Windows.Forms.NumericUpDown MaxRange_UpDown;
		private System.Windows.Forms.GroupBox CheckRange_GroupBox;
		private System.Windows.Forms.ToolTip CheckRange_Tooltip;
		private System.Windows.Forms.NumericUpDown CheckRange_UpDown;
		private System.Windows.Forms.GroupBox PauseForLoot_GroupBox;
		private System.Windows.Forms.ToolTip PauseForLoot_Tooltip;
		private System.Windows.Forms.NumericUpDown PauseForLoot_UpDown;
		private System.Windows.Forms.GroupBox LogLevel_GroupBox;
		private System.Windows.Forms.ComboBox LogLevel_ComboBox;
		private System.Windows.Forms.ToolTip LogLevel_Tooltip;
		private System.Windows.Forms.Button Save_Button;

		/// <summary>
		/// Add Player Dialog
		/// </summary>
		private System.Windows.Forms.ComboBox Players_ComboBox;
		private System.Windows.Forms.Label Players_Label;
		private System.Windows.Forms.Button AddPlayer_Button;
		private System.Windows.Forms.Form Add_Player_Form;

		/// <summary>
		/// GUI Initialization
		/// </summary>
		private void InitializeComponent() {
			this.PluginPanel = new System.Windows.Forms.Panel();
			this.Leader_GroupBox = new System.Windows.Forms.GroupBox();
			this.Leader_Tooltip = new System.Windows.Forms.ToolTip();
			this.Remove_Button = new System.Windows.Forms.Button();
			this.Add_Button = new System.Windows.Forms.Button();
			this.Add_Button_Tooltip = new System.Windows.Forms.ToolTip();
			this.Leader_ListBox = new System.Windows.Forms.ListBox();
			this.MinRange_GroupBox = new System.Windows.Forms.GroupBox();
			this.MinRange_Tooltip = new System.Windows.Forms.ToolTip();
			this.MinRange_UpDown = new System.Windows.Forms.NumericUpDown();
			this.MaxRange_GroupBox = new System.Windows.Forms.GroupBox();
			this.MaxRange_Tooltip = new System.Windows.Forms.ToolTip();
			this.MaxRange_UpDown = new System.Windows.Forms.NumericUpDown();
			this.CheckRange_GroupBox = new System.Windows.Forms.GroupBox();
			this.CheckRange_Tooltip = new System.Windows.Forms.ToolTip();
			this.CheckRange_UpDown = new System.Windows.Forms.NumericUpDown();
			this.PauseForLoot_GroupBox = new System.Windows.Forms.GroupBox();
			this.PauseForLoot_Tooltip = new System.Windows.Forms.ToolTip();
			this.PauseForLoot_UpDown = new System.Windows.Forms.NumericUpDown();
			this.LogLevel_GroupBox = new System.Windows.Forms.GroupBox();
			this.LogLevel_ComboBox = new System.Windows.Forms.ComboBox();
			this.LogLevel_Tooltip = new System.Windows.Forms.ToolTip();
			this.Save_Button = new System.Windows.Forms.Button();
			this.Leader_GroupBox.SuspendLayout();
			this.MinRange_GroupBox.SuspendLayout();
			((System.ComponentModel.ISupportInitialize)(this.MinRange_UpDown)).BeginInit();
			this.MaxRange_GroupBox.SuspendLayout();
			((System.ComponentModel.ISupportInitialize)(this.MaxRange_UpDown)).BeginInit();
			this.CheckRange_GroupBox.SuspendLayout();
			((System.ComponentModel.ISupportInitialize)(this.CheckRange_UpDown)).BeginInit();
			
			// 
			// Leader_GroupBox
			// 
			this.Leader_GroupBox.Controls.Add(this.Remove_Button);
			this.Leader_GroupBox.Controls.Add(this.Add_Button);
			this.Leader_GroupBox.Controls.Add(this.Leader_ListBox);
			this.Leader_GroupBox.Location = new System.Drawing.Point(8, 8);
			this.Leader_GroupBox.Name = "Leader_GroupBox";
			this.Leader_GroupBox.Size = new System.Drawing.Size(200, 308);
			this.Leader_GroupBox.TabIndex = 0;
			this.Leader_GroupBox.TabStop = false;
			this.Leader_GroupBox.Text = "Leaders:";
			// 
			// Leader_ListBox
			// 
			this.Leader_ListBox.FormattingEnabled = true;
			this.Leader_ListBox.Location = new System.Drawing.Point(6, 19);
			this.Leader_ListBox.Name = "Leader_ListBox";
			this.Leader_ListBox.Size = new System.Drawing.Size(188, 251);
			this.Leader_ListBox.TabIndex = 1;
			// 
			// Leader_Tooltip
			// 
			this.Leader_Tooltip.AutoPopDelay = 60000;
			this.Leader_Tooltip.InitialDelay = 500;
			this.Leader_Tooltip.IsBalloon = true;
			this.Leader_Tooltip.ReshowDelay = 100;
			this.Leader_Tooltip.ToolTipTitle = this.Leader_GroupBox.Text;
			this.Leader_Tooltip.SetToolTip(this.Leader_ListBox, "Add Players for the Bot to follow.\nNOTE: Add Players by the priority you want them followed.");
			// 
			// Remove_Button
			// 
			this.Remove_Button.Location = new System.Drawing.Point(6, 276);
			this.Remove_Button.Name = "Remove_Button";
			this.Remove_Button.Size = new System.Drawing.Size(75, 23);
			this.Remove_Button.TabIndex = 2;
			this.Remove_Button.Text = "Remove";
			this.Remove_Button.UseVisualStyleBackColor = true;
			this.Remove_Button.Click += new System.EventHandler(this.Remove_Button_Click);
			// 
			// Add_Button
			// 
			this.Add_Button.Enabled = false;
			this.Add_Button.Location = new System.Drawing.Point(119, 276);
			this.Add_Button.Name = "Add_Button";
			this.Add_Button.Size = new System.Drawing.Size(75, 23);
			this.Add_Button.TabIndex = 3;
			this.Add_Button.Text = "Add";
			this.Add_Button.UseVisualStyleBackColor = true;
			this.Add_Button.Click += new System.EventHandler(this.Add_Button_Click);
			// 
			// Add_Button_Tooltip
			// 
			this.Add_Button_Tooltip.AutoPopDelay = 60000;
			this.Add_Button_Tooltip.InitialDelay = 500;
			this.Add_Button_Tooltip.IsBalloon = true;
			this.Add_Button_Tooltip.ReshowDelay = 100;
			this.Add_Button_Tooltip.ToolTipTitle = "Add Leader";
			this.Add_Button_Tooltip.SetToolTip(this.Add_Button, "To enable this button, you need to run the plugin briefly.");
			// 
			// MinRange_GroupBox
			// 
			this.MinRange_GroupBox.Controls.Add(this.MinRange_UpDown);
			this.MinRange_GroupBox.Location = new System.Drawing.Point(214, 8);
			this.MinRange_GroupBox.Name = "MinRange_GroupBox";
			this.MinRange_GroupBox.Size = new System.Drawing.Size(107, 46);
			this.MinRange_GroupBox.TabIndex = 4;
			this.MinRange_GroupBox.TabStop = false;
			this.MinRange_GroupBox.Text = "Min Range:";
			// 
			// MinRange_UpDown
			// 
			this.MinRange_UpDown.Location = new System.Drawing.Point(6, 19);
			this.MinRange_UpDown.Maximum = new decimal(new int[] { 25, 0, 0, 0 });
			this.MinRange_UpDown.Minimum = new decimal(new int[] { 4, 0, 0, 0 });
			this.MinRange_UpDown.Name = "MinRange_UpDown";
			this.MinRange_UpDown.Size = new System.Drawing.Size(94, 20);
			this.MinRange_UpDown.TabIndex = 5;
			this.MinRange_UpDown.Value = new decimal(new int[] { 5, 0, 0, 0 });
			// 
			// MinRange_Tooltip
			// 
			this.MinRange_Tooltip.AutoPopDelay = 60000;
			this.MinRange_Tooltip.InitialDelay = 500;
			this.MinRange_Tooltip.IsBalloon = true;
			this.MinRange_Tooltip.ReshowDelay = 100;
			this.MinRange_Tooltip.ToolTipTitle = "Information";
			this.MinRange_Tooltip.SetToolTip(this.MinRange_UpDown, "Minimum range before the Bot attempts to follow a Leader.\nNote: The Bot won't start moving until the Leader is further than this distance.");
			// 
			// MaxRange_GroupBox
			// 
			this.MaxRange_GroupBox.Controls.Add(this.MaxRange_UpDown);
			this.MaxRange_GroupBox.Location = new System.Drawing.Point(214, 60);
			this.MaxRange_GroupBox.Name = "MaxRange_GroupBox";
			this.MaxRange_GroupBox.Size = new System.Drawing.Size(107, 46);
			this.MaxRange_GroupBox.TabIndex = 6;
			this.MaxRange_GroupBox.TabStop = false;
			this.MaxRange_GroupBox.Text = "Max Range:";
			// 
			// MaxRange_UpDown
			// 
			this.MaxRange_UpDown.Location = new System.Drawing.Point(6, 19);
			this.MaxRange_UpDown.Name = "MaxRange_UpDown";
			this.MaxRange_UpDown.Size = new System.Drawing.Size(94, 20);
			this.MaxRange_UpDown.TabIndex = 7;
			this.MaxRange_UpDown.Value = new decimal(new int[] { 20, 0, 0, 0 });
			// 
			// MaxRange_Tooltip
			// 
			this.MaxRange_Tooltip.AutoPopDelay = 60000;
			this.MaxRange_Tooltip.InitialDelay = 500;
			this.MaxRange_Tooltip.IsBalloon = true;
			this.MaxRange_Tooltip.ReshowDelay = 100;
			this.MaxRange_Tooltip.ToolTipTitle = "Information";
			this.MaxRange_Tooltip.SetToolTip(this.MaxRange_UpDown, "Maximum range the bot will attempt to follow a Leader.\nNote: After the Leader has moved passed this distance, the Bot will stop following until the Leader returns.");
			// 
			// CheckRange_GroupBox
			// 
			this.CheckRange_GroupBox.Controls.Add(this.CheckRange_UpDown);
			this.CheckRange_GroupBox.Location = new System.Drawing.Point(214, 112);
			this.CheckRange_GroupBox.Name = "CheckRange_GroupBox";
			this.CheckRange_GroupBox.Size = new System.Drawing.Size(107, 46);
			this.CheckRange_GroupBox.TabIndex = 8;
			this.CheckRange_GroupBox.TabStop = false;
			this.CheckRange_GroupBox.Text = "Check Range:";
			// 
			// CheckRange_UpDown
			// 
			this.CheckRange_UpDown.Location = new System.Drawing.Point(6, 19);
			this.CheckRange_UpDown.Maximum = new decimal(new int[] { 25, 0, 0, 0 });
			this.CheckRange_UpDown.Name = "CheckRange_UpDown";
			this.CheckRange_UpDown.Size = new System.Drawing.Size(94, 20);
			this.CheckRange_UpDown.TabIndex = 9;
			this.CheckRange_UpDown.Value = new decimal(new int[] { 10, 0, 0, 0 });
			// 
			// CheckRange_Tooltip
			// 
			this.CheckRange_Tooltip.AutoPopDelay = 60000;
			this.CheckRange_Tooltip.InitialDelay = 500;
			this.CheckRange_Tooltip.IsBalloon = true;
			this.CheckRange_Tooltip.ReshowDelay = 100;
			this.CheckRange_Tooltip.ToolTipTitle = "Information";
			this.CheckRange_Tooltip.SetToolTip(this.CheckRange_UpDown, "Maximum distance unknown Player can be before the Bot attempts to identify them.\nNote: The bot will need to face the Player to identify, it is probably a good idea to keep this range small.");
			// 
			// PauseForLoot_GroupBox
			// 
			this.PauseForLoot_GroupBox.Controls.Add(this.PauseForLoot_UpDown);
			this.PauseForLoot_GroupBox.Location = new System.Drawing.Point(214, 164);
			this.PauseForLoot_GroupBox.Name = "PauseForLoot_GroupBox";
			this.PauseForLoot_GroupBox.Size = new System.Drawing.Size(107, 46);
			this.PauseForLoot_GroupBox.TabIndex = 10;
			this.PauseForLoot_GroupBox.TabStop = false;
			this.PauseForLoot_GroupBox.Text = "Pause for Loot:";
			// 
			// PauseForLoot_UpDown
			// 
			this.PauseForLoot_UpDown.Location = new System.Drawing.Point(6, 19);
			this.PauseForLoot_UpDown.Maximum = new decimal(new int[] { 20, 0, 0, 0 });
			this.PauseForLoot_UpDown.Name = "PauseForLoot_UpDown";
			this.PauseForLoot_UpDown.Size = new System.Drawing.Size(94, 20);
			this.PauseForLoot_UpDown.TabIndex = 11;
			this.PauseForLoot_UpDown.Value = new decimal(new int[] { 5, 0, 0, 0 });
			// 
			// PauseForLoot_Tooltip
			// 
			this.PauseForLoot_Tooltip.AutoPopDelay = 60000;
			this.PauseForLoot_Tooltip.InitialDelay = 500;
			this.PauseForLoot_Tooltip.IsBalloon = true;
			this.PauseForLoot_Tooltip.ReshowDelay = 100;
			this.PauseForLoot_Tooltip.ToolTipTitle = "Information";
			this.PauseForLoot_Tooltip.SetToolTip(this.PauseForLoot_UpDown, "The amount of time in seconds the Bot should pause after a fight before resuming following.\nNote: This is meant to allow the bot time to gather loot, a long period of time shouldn't be necessary.");
			// 
			// LogLevel_GroupBox
			// 
			this.LogLevel_GroupBox.Controls.Add(this.LogLevel_ComboBox);
			this.LogLevel_GroupBox.Location = new System.Drawing.Point(214, 216);
			this.LogLevel_GroupBox.Name = "LogLevel_GroupBox";
			this.LogLevel_GroupBox.Size = new System.Drawing.Size(107, 46);
			this.LogLevel_GroupBox.TabIndex = 12;
			this.LogLevel_GroupBox.TabStop = false;
			this.LogLevel_GroupBox.Text = "Log Level:";
			// 
			// LogLevel_ComboBox
			// 
			this.LogLevel_ComboBox.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
			this.LogLevel_ComboBox.FormattingEnabled = true;
			this.LogLevel_ComboBox.Location = new System.Drawing.Point(6, 19);
			this.LogLevel_ComboBox.Margin = new System.Windows.Forms.Padding(4, 5, 4, 5);
			this.LogLevel_ComboBox.Name = "LogLevel_ComboBox";
			this.LogLevel_ComboBox.Size = new System.Drawing.Size(94, 21);
			this.LogLevel_ComboBox.TabIndex = 13;
			// 
			// LogLevel_Tooltip
			// 
			this.LogLevel_Tooltip.AutoPopDelay = 60000;
			this.LogLevel_Tooltip.InitialDelay = 500;
			this.LogLevel_Tooltip.IsBalloon = true;
			this.LogLevel_Tooltip.ReshowDelay = 100;
			this.LogLevel_Tooltip.ToolTipTitle = this.LogLevel_GroupBox.Text;
			this.LogLevel_Tooltip.SetToolTip(this.LogLevel_ComboBox, "The Level of detail the log files should produce.\nNote: Should be set to Basic unless troubleshooting.");
			// 
			// Save_Button
			// 
			this.Save_Button.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
			this.Save_Button.Location = new System.Drawing.Point(220, 268);
			this.Save_Button.Name = "Save_Button";
			this.Save_Button.Size = new System.Drawing.Size(94, 39);
			this.Save_Button.TabIndex = 14;
			this.Save_Button.Text = "Save";
			this.Save_Button.UseVisualStyleBackColor = true;
			this.Save_Button.Click += new System.EventHandler(this.Save_Button_Click);
			// 
			// UsersFollowBot_Form
			// 
			this.Leader_GroupBox.ResumeLayout(false);
			this.MinRange_GroupBox.ResumeLayout(false);
			((System.ComponentModel.ISupportInitialize)(this.MinRange_UpDown)).EndInit();
			this.MaxRange_GroupBox.ResumeLayout(false);
			((System.ComponentModel.ISupportInitialize)(this.MaxRange_UpDown)).EndInit();
			this.CheckRange_GroupBox.ResumeLayout(false);
			((System.ComponentModel.ISupportInitialize)(this.CheckRange_UpDown)).EndInit();
			this.PauseForLoot_GroupBox.ResumeLayout(false);
			((System.ComponentModel.ISupportInitialize)(this.PauseForLoot_UpDown)).EndInit();
			this.LogLevel_GroupBox.ResumeLayout(false);
			// 
			// PluginPanel
			//
			this.PluginPanel.Controls.Add(this.LogLevel_GroupBox);
			this.PluginPanel.Controls.Add(this.PauseForLoot_GroupBox);
			this.PluginPanel.Controls.Add(this.Save_Button);
			this.PluginPanel.Controls.Add(this.CheckRange_GroupBox);
			this.PluginPanel.Controls.Add(this.MaxRange_GroupBox);
			this.PluginPanel.Controls.Add(this.MinRange_GroupBox);
			this.PluginPanel.Controls.Add(this.Leader_GroupBox);
			this.PluginPanel.Location = new System.Drawing.Point(12, 12);
			this.PluginPanel.Name = "PluginPanel";
			this.PluginPanel.Size = new System.Drawing.Size(319, 314);
			this.PluginPanel.TabIndex = 15;
			
			//
			// Add Player Dialog
			//
			this.Players_ComboBox = new System.Windows.Forms.ComboBox();
			this.Players_Label = new System.Windows.Forms.Label();
			this.AddPlayer_Button = new System.Windows.Forms.Button();
			this.Add_Player_Form = new System.Windows.Forms.Form();
			Add_Player_Form.SuspendLayout();
			// 
			// Players_ComboBox
			// 
			this.Players_ComboBox.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
			this.Players_ComboBox.FormattingEnabled = true;
			this.Players_ComboBox.Location = new System.Drawing.Point(15, 25);
			this.Players_ComboBox.Name = "Players_ComboBox";
			this.Players_ComboBox.Size = new System.Drawing.Size(246, 21);
			this.Players_ComboBox.TabIndex = 0;
			// 
			// Players_Label
			// 
			this.Players_Label.AutoSize = true;
			this.Players_Label.Location = new System.Drawing.Point(12, 9);
			this.Players_Label.Name = "Players_Label";
			this.Players_Label.Size = new System.Drawing.Size(101, 13);
			this.Players_Label.TabIndex = 1;
			this.Players_Label.Text = "Discovered Players:";
			// 
			// AddPlayer_Button
			// 
			this.AddPlayer_Button.Location = new System.Drawing.Point(188, 52);
			this.AddPlayer_Button.Name = "AddPlayer_Button";
			this.AddPlayer_Button.Size = new System.Drawing.Size(75, 23);
			this.AddPlayer_Button.TabIndex = 2;
			this.AddPlayer_Button.Text = "Add Player";
			this.AddPlayer_Button.UseVisualStyleBackColor = true;
			this.AddPlayer_Button.Click += new System.EventHandler(this.AddPlayer_Button_Click);

			// 
			// AddPlayer_Form
			// 
			Add_Player_Form.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			Add_Player_Form.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			Add_Player_Form.ClientSize = new System.Drawing.Size(278, 84);
			Add_Player_Form.Controls.Add(this.AddPlayer_Button);
			Add_Player_Form.Controls.Add(this.Players_Label);
			Add_Player_Form.Controls.Add(this.Players_ComboBox);
			Add_Player_Form.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
			Add_Player_Form.MaximizeBox = false;
			Add_Player_Form.MinimizeBox = false;
			Add_Player_Form.Name = "AddPlayer_Form";
			Add_Player_Form.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
			Add_Player_Form.Text = "Add Player";
			Add_Player_Form.ResumeLayout(false);
			Add_Player_Form.PerformLayout();
		}

		/// <summary>
		/// Presents the Add Player Dialog when the plugin is running
		/// </summary>
		private void Add_Button_Click(object sender, EventArgs e) {
			// Verify the Bot is running
			if (Bot != null) {
				// Discover Identified Players nearby
				List<string> findPlayers = Bot
					.GetMobArray
					.AsParallel()
					.Where(p =>
						p.isValid &&
						p.Type == 2 &&
						Player.DistanceTo(p) < maxRange &&
						!Leader_ListBox.Items.Contains(p.Name) &&
						p.WGUID != Player.WGUID &&
						p.Name != "Player")
					.Select(n => n.Name)
					.ToList();
				
				// Clear the Players ComboBox
				Players_ComboBox.Items.Clear();
				
				// Add discovered Players
				if (findPlayers.Count() > 0) {
					Players_ComboBox.Items.AddRange(findPlayers.ToArray());
				}
				
				// Show the Dialog
				Add_Player_Form.ShowDialog();
			}
		}

		/// <summary>
		/// Removes the selected Player from the list
		/// </summary>
		private void Remove_Button_Click(object sender, EventArgs e) {
			// Remove the Leader from the ListBox
			Leader_ListBox.Items.Remove(Leader_ListBox.SelectedItem);
		}

		/// <summary>
		/// Saves the current Options
		/// </summary>
		private void Save_Button_Click(object sender, EventArgs e) {
			// Save Settings
			saveSettings();
		}

		/// <summary>
		/// Adds the selected Player to the list
		/// </summary>
		private void AddPlayer_Button_Click(object sender, EventArgs e) {
			// Add the Leader to the ListBox
			Leader_ListBox.Items.Add(Players_ComboBox.SelectedItem);

			// Close the Dialog
			Add_Player_Form.Close();
		}

		/// <summary>
		/// Initialize default values
		/// </summary>
		private void initializeBot() {
			if (!isInitialized) {
				// Clear the list to ensure fresh values
				leaderList.Clear();

				// Set Default Log Level
				_currentLogLevel = logLevel.Basic;

				// Set Default minRange
				minRange = 5f;

				// Set Default maxRange
				maxRange = 20f;

				// Set Default checkRange
				checkRange = 10f;

				// Set Default pauseForLootSeconds
				pauseForLootSeconds = 4;

				// Set isInitialized to true
				isInitialized = true;
			}
		}

		/// <summary>
		/// Load settings from File to Fields and Form
		/// </summary>
		private void loadSettings() {
			// Load from the File
			if (System.IO.File.Exists("Resources\\Plugins\\" + this.Name.Replace("'", "").Replace(" ", "") + ".ini")) {
				IniFile thisIniFile = new IniFile("Resources\\Plugins\\" + this.Name.Replace("'", "").Replace(" ", ""));

				// Set minRange
				try {
					minRange = float.Parse(thisIniFile.Read("Range.Min"));
				} catch (Exception ex) {
					log(String.Format("There was a problem loading the Min Range setting, setting Default to: {0}", minRange));
					log(String.Format("Error Message: \n{0}", ex.Message));
				}

				// Set maxRange
				try {
					maxRange = float.Parse(thisIniFile.Read("Range.Max"));
				} catch (Exception ex) {
					log(String.Format("There was a problem loading the Max Range setting, setting default to: {0}", maxRange));
					log(String.Format("Error Message: \n{0}", ex.Message));
				}

				// Set checkRange
				try {
					checkRange = float.Parse(thisIniFile.Read("Range.Check"));
				} catch (Exception ex) {
					log(String.Format("There was a problem loading the Check Range setting, setting default to: {0}", checkRange));
					log(String.Format("Error Message: \n{0}", ex.Message));
				}

				// Set pauseForLootSeconds
				try {
					pauseForLootSeconds = int.Parse(thisIniFile.Read("Pause.Loot"));
				} catch (Exception ex) {
					log(String.Format("There was a problem loading the Pause for Loot setting, setting default to: {0}", pauseForLootSeconds));
					log(String.Format("Error Message: \n{0}", ex.Message));
				}

				// Set Log Level
				try {
					// Set the Log Level
					_currentLogLevel = (logLevel)int.Parse(thisIniFile.Read("Log.Level"));
				} catch (Exception ex) {
					log(String.Format("There was a problem loading the Log Level setting, setting default to: {0}", _currentLogLevel));
					log(String.Format("Error Message: \n{0}", ex.Message));
				}

				// Set Leaders
				try {
					leaderNames = thisIniFile.Read("Leader.Names");

					// declare the delimeter string
					string[] delimeterChar = { "|" };

					// Clear the list to ensure fresh values
					leaderList.Clear();

					// Add Players by priority, highest priority first
					string[] splitLeaderNames = leaderNames.Split(delimeterChar, StringSplitOptions.RemoveEmptyEntries);
					leaderList.AddRange(splitLeaderNames);
				} catch (Exception ex) {
					log(String.Format("There was a problem loading the Leader List: \"{0}\"", leaderNames));
					log(String.Format("Error Message: \n{0}", ex.Message));
					throw new ArgumentNullException(String.Format("Unable to load Player List {0} cannot continue, aborting", this.Name));
				}
			}

			// Set minRange
			try {
				MinRange_UpDown.Value = (int)minRange;
			} catch (Exception ex) {
				log(String.Format("There was a problem loading the Min Range setting on the form"));
				log(String.Format("Error Message: \n{0}", ex.Message));
			}

			// Set maxRange
			try {
				MaxRange_UpDown.Value = (int)maxRange;
			} catch (Exception ex) {
				log(String.Format("There was a problem loading the Max Range setting on the form"));
				log(String.Format("Error Message: \n{0}", ex.Message));
			}

			// Set checkRange
			try {
				CheckRange_UpDown.Value = (int)checkRange;
			} catch (Exception ex) {
				log(String.Format("There was a problem loading the Check Range setting on the form"));
				log(String.Format("Error Message: \n{0}", ex.Message));
			}

			// Set pauseForLootSeconds
			try {
				PauseForLoot_UpDown.Value = pauseForLootSeconds;
			} catch (Exception ex) {
				log(String.Format("There was a problem loading the Pause for Loot setting on the form"));
				log(String.Format("Error Message: \n{0}", ex.Message));
			}

			// Set Log Level
			try {
				// Clear LogLevel ComboBox
				LogLevel_ComboBox.Items.Clear();

				// Populate LogLevel ComboBox
				foreach (logLevel log in Enum.GetValues(typeof(logLevel))) {
					ComboboxItem item = new ComboboxItem();
					item.Text = log.ToString();
					item.Value = (int)log;
					LogLevel_ComboBox.Items.Add(log);
				}

				// Set Log Level
				LogLevel_ComboBox.SelectedIndex = (int)_currentLogLevel;
			} catch (Exception ex) {
				log("There was a problem populating the form, defaults have been used.");
				log(String.Format("Error Message: \n{0}", ex.Message));
			}

			// Set Player List
			try {
				Leader_ListBox.Items.AddRange(leaderList.ToArray());
			} catch (Exception ex) {
				log("There was a problem populating the form, defaults have been used.");
				log(String.Format("Error Message: \n{0}", ex.Message));
			}
		}

		/// <summary>
		/// Save settings from Form to fields and File
		/// </summary>
		private void saveSettings() {
			// Initialize the ini file
			IniFile thisIniFile = new IniFile("Resources\\Plugins\\" + this.Name.Replace("'", "").Replace(" ", ""));

			// Set minRange
			try {
				minRange = (float)MinRange_UpDown.Value;
				thisIniFile.Write("Range.Min", minRange.ToString());
			} catch (Exception ex) {
				log(String.Format("There was a problem saving the Min Range setting, setting Default to: {0}", minRange));
				log(String.Format("Error Message: \n{0}", ex.Message));
			}

			// Set maxRange
			try {
				maxRange = (float)MaxRange_UpDown.Value;
				thisIniFile.Write("Range.Max", maxRange.ToString());
			} catch (Exception ex) {
				log(String.Format("There was a problem saving the Max Range setting, setting default to: {0}", maxRange));
				log(String.Format("Error Message: \n{0}", ex.Message));
			}

			// Set checkRange
			try {
				checkRange = (float)CheckRange_UpDown.Value;
				thisIniFile.Write("Range.Check", checkRange.ToString());
			} catch (Exception ex) {
				log(String.Format("There was a problem saving the Check Range setting, setting default to: {0}", checkRange));
				log(String.Format("Error Message: \n{0}", ex.Message));
			}

			// Set pauseForLootSeconds
			try {
				pauseForLootSeconds = (int)PauseForLoot_UpDown.Value;
				thisIniFile.Write("Pause.Loot", pauseForLootSeconds.ToString());
			} catch (Exception ex) {
				log(String.Format("There was a problem saving the Pause for Loot setting, setting default to: {0}", pauseForLootSeconds));
				log(String.Format("Error Message: \n{0}", ex.Message));
			}

			// Set _currentLogLevel
			try {
				_currentLogLevel = (logLevel)LogLevel_ComboBox.SelectedIndex;
				thisIniFile.Write("Log.Level", ((int)_currentLogLevel).ToString());
			} catch (Exception ex) {
				log(String.Format("There was a problem saving the Log Level setting, setting default to: {0}", _currentLogLevel));
				log(String.Format("Error Message: \n{0}", ex.Message));
			}

			// Set Leaders
			try {
				// Clear the list to ensure fresh values
				leaderList.Clear();

				// Add Leaders to playserList
				foreach (string p in Leader_ListBox.Items) {
					leaderList.Add(p);
				}

				// Convert the name list to string
				leaderNames = string.Join("|", leaderList.ToArray());

				// Write Leadernames to settings file
				thisIniFile.Write("Leader.Names", leaderNames);
			} catch (Exception ex) {
				log(String.Format("There was a problem saving the Leader List: \"{0}\"", leaderNames));
				log(String.Format("Error Message: \n{0}", ex.Message));
				throw new ArgumentNullException(String.Format("Unable to load Player List {0} cannot continue, aborting", this.Name));
			}
		}

		#endregion

		#region Radar Code Region

		/// <summary>
		/// Indicates if the Thread is currently running
		/// </summary>
		bool isScanning = false;

		/// <summary>
		/// Thread executes the radarThread_Tick() method in a new Thread.
		/// </summary>
		Thread radarThread;
		
		/// <summary>
		/// Method to execute by the thread, aggro finding code belongs here
		/// </summary>
		private void radarThread_Tick() {
			// Verify not already Scanning
			if (!isScanning) {
				// Set isScanning = true
				isScanning = true;

				// Verify not in Combat
				if (!isFighting) {
					// Update Leader List
					updatePriorityLeader(cacheEntities.Where(c => c.Type == 2).ToList());
				}

				// Update Aggro List
				updateAggroList(cacheEntities.Where(c => c.Type == 3).ToList());

				// Set isScanning = false
				isScanning = false;
			}
		}

		/// <summary>
		/// Finds and Updates Mob/Players aggroing the group
		/// </summary>
		/// <param name="MobList">List of previously filtered IMobs</param>
		private void updateAggroList(List<IMob> MobList) {
			// Update the log
			string petList = "Unstable Familiar|Clannfear|Volatile Familiar|Shadowy Clannfear|Winged Twilight|Twilight Tormentor|Twilight Matriarch|Storm Atronach|Greater Storm Atronach|Charged Atronach";

			// Build a List of Pet WGUIDs
			string petGUIDs = string.Join("|", 
				MobList.Where(l => 
					Player.DistanceTo(l) <= checkRange &&
					petList.Contains(l.Name)
				)
				.Select(w => w.WGUID)
				.ToArray());

			// Build a List of Leader GUIDs with Pet GUIDs
			string filterGUIDs = String.Format("{0}{1}{2}", leaderGUIDs, (petGUIDs != "")?"|":"", petGUIDs);

			// Set the targets to IMobs targeting IPlayer
			List<IMob> targetList = 
				MobList.Where(t => 
					t.CurHP > 0 && 
					filterGUIDs.Contains(t.Target.ToString()) &&
					!petList.Contains(t.Name)
				)
				.ToList();
			foreach (IMob m in targetList) {
				m.Target = Player.WGUID;
				log(String.Format("Found Target: {0}", m.Name), logLevel.Debug);
			}
		}

		/// <summary>
		/// Determines the Leader this Bot should be following
		/// </summary>
		/// <param name="MobList">List of previously filtered IMobs</param>
		private void updatePriorityLeader(List<IMob> MobList) {
			// Check if leaderList has Leaders and the current Leader is not highest priority Leader
			if (leaderList.Count() > 0 && Leader.Name != leaderList.FirstOrDefault()) {
				// Set the initial Default target to Bot
				IMob leader = Player;

				// Target & face all nearby Players to capture their name
				List<IMob> playerList = MobList.Where(p => p.Name == "Player" && Player.DistanceTo(p) <= checkRange).ToList();

				// Check if playerList has Players
				if (playerList.Count() > 0) {
					// Update Log
					log("Target & face all nearby Players to capture their name", logLevel.Debug);

					// Make sure Bot isn't moving during this
					if (Bot.Navigation.Running) {
						Bot.Navigation.Hardstop();
					}

					// Cycle through discovered Players
					foreach (IMob p in playerList) {
						// Target & Face Player
						Bot.Navigation.FaceMob(p);

						// Update the log
						if (p.Name != "Player") {
							log(String.Format("Discovered Player: {0}", p.Name), logLevel.Debug);
						}
					}
				}

				// Get all nearby Leaders
				List<IMob> listLeaders = MobList.Where(p => leaderNames.Contains(p.Name)).ToList();

				// Build a List of Leader WGUIDs
				leaderGUIDs = string.Join("|", listLeaders.Select(w => w.WGUID).ToArray());

				// Verify the Leader List Contains at least one Leader
				if (listLeaders.Count() > 0) {
					// Set flag to determine if a LEader was discovered
					bool foundLeader = false;

					// Cycle through discovered Leaders by their original order
					for (int i = 0; i < listLeaders.Count(); i++) {
						// Create a temporary reference to the current IMob for easier reading
						IMob p = listLeaders[i];

						// Check Player Range
						if (Player.DistanceTo(p) <= checkRange) {
							// Discovered Leader
							log(String.Format("Discovered Leader: {0}", p.Name), logLevel.Debug);

							leader = p;
							foundLeader = true;
							break;
						}
					}

					// If a Leader hasn't been discovered, select the closest Leader
					if (!foundLeader) {
						// Sort discovered Leaders by distance from Bot
						listLeaders.Sort(delegate (IMob a, IMob b) {
							return a.DistanceTo(leader).CompareTo(b.DistanceTo(leader));
						});

						// Create a temporary reference to the current IMob for easier reading
						IMob p = listLeaders.FirstOrDefault();

						// Discovered Leader
						log(String.Format("Discovered Leader: {0}", p.Name), logLevel.Debug);
						leader = p;
					}
				}

				// Update Leader
				Leader = leader;
			}
		}

		#endregion

		#region Movement Code Region

		/// <summary>
		/// Indicates if the bot is currently moving
		/// </summary>
		bool isMoving = false;

		/// <summary>
		/// Thread executes the moveThread_Tick() method in a new Thread.
		/// </summary>
		Thread moveThread;

		/// <summary>
		/// Timer is used to automatically shut off movement after the time has passed.
		/// </summary>
		HighResTimer refreshMoveTime = new HighResTimer();

		/// <summary>
		/// The amount of time to allow the thread to run without refresh before shutting off.
		/// </summary>
		int refreshMoveSeconds = 5;

		/// <summary>
		/// Method to execute by the thread, movement code belongs here
		/// </summary>
		private void moveThread_Tick() {
			// Verify not Fighting and not in Combat
			if (!isFighting && !isMoving) {
				// Set isMoving to true
				isMoving = true;

				while (isMoving) {
					// Check to see if we need to abort
					if (isFighting || refreshMoveTime.ElapsedSeconds > refreshMoveSeconds) {
						break;
					}

					// Check Distance to Leader
					float _distance = Player.DistanceTo(Leader.X, Leader.Y, Leader.Z);
					if (_distance > minRange && _distance < maxRange) {
						// Move towards the player. Using MoveToHotspot so the bot will leverage any navmesh that has been added
						Bot.Navigation.MoveToHotSpot(Leader.X, Leader.Y, Leader.Z, (minRange / 2), false);
					} else {
						// Check if the Bot is Running
						if (Bot.Navigation.Running) {
							// Stop the Bot
							Bot.Navigation.Stop();
						}
					}

					Thread.Sleep(100);
					Application.DoEvents();
				}
				
				// Stop the Bot from moving
				Bot.Navigation.Hardstop();

				// Set isMoving to false
				isMoving = false;
			}
		}

		#endregion

		#region MMOViper Plugin Properties

		/// <summary>
		/// Used by MMOViper to identify this plugin
		/// </summary>
		public string Name { get { return "UFB"; } }

		/// <summary>
		/// Used by MMOViper to give you props for your plugin
		/// </summary>
		public string Author { get { return "User's Follow Bot"; } }

		/// <summary>
		/// Used by MMOViper for additional information about this plugin
		/// </summary>
		public string Description { get { return "Follow Bot Plugin designed to Follow Player(s) and assist killing mobs"; } }

		/// <summary>
		/// Used by MMOViper to identify the current version
		/// </summary>
		public float Version { get { return 1.0f; } }

		/// <summary>
		/// Used by MMOViper to determine if it should add UI elements
		/// </summary>
		/// <returns>return true if the plugin needs to add UI elements</returns>
		public bool WantsButton { get { return true; } }
		
		/// <summary>
		/// Used by MMOViper to retrieve UI elements
		/// </summary>
		public Panel Panel {
			get {
				loadSettings();
				return PluginPanel;
			}
		}

		/// <summary>
		/// Used by MMOViper to temporarily store tasks
		/// </summary>
		public List<string> Tasks {
			get {
				return new List<string>();
			}
		}

		/// <summary>
		/// Used by MMOViper to retrieve automatic updates
		/// </summary>
		public string AutoUpdateWebPath {
			get {
				return "";
			}
		}

		/// <summary>
		/// Used by MMOViper to document the source URL
		/// </summary>
		public string Url { get { return "https://gumroad.com/l/MBStdN";} }

		/// <summary>
		/// Used by MMOViper to determine if this plugin needs control
		/// </summary>
		/// <returns>return true if the plugin needs to maintain control</returns>
		public bool NeedsToRun {
			get {
				// Set Leader to Bot to start
				if (isFirstRun) {
					// Setting Player Default
					Player = Bot.Player;

					// Setting Leader Default
					Leader = Player;

					// Set isFirstRun to false
					isFirstRun = false;
				}

				// Refresh cacheEntities
				cacheEntities.Clear();
				foreach (IMob e in Bot.GetMobArray) {
					if (
						Player.DistanceTo(e) < maxRange &&
						e.isValid &&
						!e.Name.Contains("Invisible") &&
						(e.Type == 2 || e.Type == 4 || (e.Type == 3 && e.Target > 0))
					) {
						cacheEntities.Add(e);
					}
				}

				// Update isFighting
				isFighting = (Bot.GetAttackers.Count() > 0) ? true : false;

				// Start the Movement Thread
				if (!isScanning) {
					// Scan for Leaders and Targets
					radarThread = new Thread(radarThread_Tick);
					radarThread.SetApartmentState(ApartmentState.STA);
					radarThread.Start();
				}

				// Scan for Leaders and Targets
				if (!isFighting) {
					if (pauseForLootTime.ElapsedSeconds > pauseForLootSeconds) {
						// Reset Movement Timer
						refreshMoveTime.Reset();

						// Start the Movement Thread
						if (!isMoving) {
							// Start the Movement Thread
							moveThread = new Thread(moveThread_Tick);
							moveThread.SetApartmentState(ApartmentState.STA);
							moveThread.Start();
						}
					}
				} else {
					// Reset Pause for Loot Timer
					pauseForLootTime.Reset();
				}

				return false;
			}
		}

		#endregion

		#region MMOViper Plugin Methods

		/// <summary>
		/// Executes when the Bot starts
		/// </summary>
		/// <param name="thisViper">Instance of the MMOViper API</param>
		public void OnBotStart(IGame thisViper) {
			// Capture IGame instance
			Bot = thisViper;
			
			// Set isFirstRun
			isFirstRun = true;
			
			// Enable the Add Button
			Add_Button.Enabled = true;
		}

		/// <summary>
		/// Executes when the Bot stops
		/// </summary>
		public void OnBotStop() { /* Do Nothing */ }

		/// <summary>
		/// Executes when the Plugin is enabled
		/// </summary>
		/// <param name="thisViper">Instance of the MMOViper API</param>
		public void OnEnabled(IGame thisViper) {
			// Capture IGame instance
			Bot = thisViper;

			// Set isFirstRun
			isFirstRun = true;
		}

		/// <summary>
		/// Executes when the Plugin is disabled
		/// </summary>
		public void OnDisabled() { /* Do Nothing */ }

		/// <summary>
		/// Executes after the Bot starts, is used for UI elements
		/// </summary>
		public void OnConfigure() {
			// Initialize all values
			initializeBot();
		}

		/// <summary>
		/// Executes when NeedsToRun is true
		/// This is a good method to put decision making code
		/// </summary>
		public void DoRun() { /* Do Nothing */ }

		/// <summary>
		/// Executes when NeedsToRun is true after DoRun() completes
		/// This is a good method to execute decisions made in DoRun()
		/// </summary>
		public void OnIdle() { /* Do Nothing */ }
		
		/// <summary>
		/// Sends text to the target plugin
		/// </summary>
		/// <param name="plugin">Originating Plugin</param>
		/// <param name="text">String message sent</param>
		public void SendMessage(IPlugin p, string text) { /* Do Nothing */ }

		/// <summary>
		/// Executes when a message is sent between Plugins
		/// </summary>
		/// <param name="plugin">Originating Plugin</param>
		/// <param name="text">String message sent</param>
		public void OnSendMessage(IPlugin fromPlugin, string text) { /* Do Nothing */ }
		
		/// <summary>
		/// Sends an object to the target plugin
		/// </summary>
		/// <param name="plugin">Target Plugin</param>
		/// <param name="obj">Object sent</param>
		public void SendObject(IPlugin p, object o) { /* Do Nothing */ }

		/// <summary>
		/// Executes when a message is sent between Plugins
		/// </summary>
		/// <param name="plugin">Originating Plugin</param>
		/// <param name="obj">Object sent</param>
		public void OnSendObject(IPlugin fromPlugin, object o) { /* Do Nothing */ }

		#endregion
	}

	/// <summary>
	/// Combobox class is used to populate the Log Level Combobox
	/// </summary>
	public class ComboboxItem {
		/// <summary>
		/// List Item's Text
		/// </summary>
		public string Text { get; set; }

		/// <summary>
		/// List Item's Value
		/// </summary>
		public object Value { get; set; }

		/// <summary>
		/// Return the String Value
		/// </summary>
		/// <returns></returns>
		public override string ToString() {
			return Text;
		}
	}
}
