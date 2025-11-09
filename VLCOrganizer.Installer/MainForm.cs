using Microsoft.Win32;
using System.Diagnostics;
using System.Security.Principal;
using System.Reflection;
using System.Text;

namespace VLCOrganizer.Installer
{
    public partial class MainForm : Form
    {
        private readonly string _defaultInstallPath;
        private Button _installButton;
        private Button _uninstallButton;
        private Button _exitButton;
        private Button _browseButton;
        private Label _statusLabel;
        private Label _pathLabel;
        private Label _installPathLabel;
        private TextBox _installPathTextBox;
        private ProgressBar _progressBar;
        private PictureBox _iconBox;

        public MainForm()
        {
            _defaultInstallPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "VLC Organizer");
            
            InitializeComponent();
            CheckCurrentStatus();
        }

        private string GetCurrentInstallPath()
        {
            return _installPathTextBox?.Text ?? _defaultInstallPath;
        }

        private string GetPowerShellScriptPath()
        {
            return Path.Combine(GetCurrentInstallPath(), "VLC-Organizer-Final.ps1");
        }

        private string GetConfigPath()
        {
            return Path.Combine(GetCurrentInstallPath(), "settings.json");
        }

        private string GetEmbeddedResource(string resourceName)
        {
            var assembly = Assembly.GetExecutingAssembly();
            var fullResourceName = $"VLCOrganizer.Installer.Resources.{resourceName}";
            
            using var stream = assembly.GetManifestResourceStream(fullResourceName);
            if (stream == null)
                throw new Exception($"Resource {resourceName} not found");
                
            using var reader = new StreamReader(stream, Encoding.UTF8);
            return reader.ReadToEnd();
        }

        private void ExtractEmbeddedFiles()
        {
            var installPath = GetCurrentInstallPath();
            
            // Criar diretório se não existir
            Directory.CreateDirectory(installPath);
            
            // Extrair script PowerShell
            var scriptContent = GetEmbeddedResource("VLC-Organizer-Final.ps1");
            File.WriteAllText(GetPowerShellScriptPath(), scriptContent, Encoding.UTF8);
            
            // Extrair configuração
            var configContent = GetEmbeddedResource("settings.json");
            File.WriteAllText(GetConfigPath(), configContent, Encoding.UTF8);
        }

        private void InitializeComponent()
        {
            // Form setup
            Text = "VLC Organizer - Instalador v2.0";
            Size = new Size(500, 480);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;

            // Icon
            _iconBox = new PictureBox
            {
                Size = new Size(48, 48),
                Location = new Point(20, 20),
                SizeMode = PictureBoxSizeMode.StretchImage
            };
            
            // Try to set VLC icon or use default
            try
            {
                var vlcPath = FindVLCPath();
                if (!string.IsNullOrEmpty(vlcPath))
                {
                    var icon = Icon.ExtractAssociatedIcon(vlcPath);
                    _iconBox.Image = icon?.ToBitmap();
                }
            }
            catch
            {
                // Use default icon if VLC icon extraction fails
            }

            // Title
            var titleLabel = new Label
            {
                Text = "🎬 VLC Organizer",
                Font = new Font("Segoe UI", 16, FontStyle.Bold),
                Location = new Point(80, 25),
                Size = new Size(300, 30),
                ForeColor = Color.DarkBlue
            };

            var subtitleLabel = new Label
            {
                Text = "Organizador Inteligente de Playlists",
                Font = new Font("Segoe UI", 10),
                Location = new Point(80, 55),
                Size = new Size(300, 20),
                ForeColor = Color.Gray
            };

            // Current location info
            _pathLabel = new Label
            {
                Text = "🔧 Instalador independente - todos os arquivos serão extraídos automaticamente",
                Location = new Point(20, 90),
                Size = new Size(440, 40),
                Font = new Font("Segoe UI", 8),
                ForeColor = Color.Gray,
                TextAlign = ContentAlignment.MiddleCenter
            };

            // Install path selection
            _installPathLabel = new Label
            {
                Text = "📁 Caminho de instalação (onde será registrado):",
                Location = new Point(20, 140),
                Size = new Size(440, 20),
                Font = new Font("Segoe UI", 9, FontStyle.Bold)
            };

            _installPathTextBox = new TextBox
            {
                Text = _defaultInstallPath,
                Location = new Point(20, 165),
                Size = new Size(360, 25),
                Font = new Font("Segoe UI", 9)
            };
            _installPathTextBox.TextChanged += (s, e) => ValidateInstallPath();

            _browseButton = new Button
            {
                Text = "📂 Procurar",
                Location = new Point(390, 164),
                Size = new Size(80, 27),
                Font = new Font("Segoe UI", 8),
                BackColor = Color.LightBlue,
                FlatStyle = FlatStyle.Flat
            };
            _browseButton.Click += BrowseButton_Click;

            // Status
            _statusLabel = new Label
            {
                Text = "Verificando status...",
                Location = new Point(20, 200),
                Size = new Size(440, 60),
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.Blue
            };

            // Progress bar
            _progressBar = new ProgressBar
            {
                Location = new Point(20, 270),
                Size = new Size(440, 23),
                Style = ProgressBarStyle.Continuous,
                Visible = false
            };

            // Buttons
            _installButton = new Button
            {
                Text = "📥 Instalar Menu de Contexto",
                Location = new Point(20, 310),
                Size = new Size(200, 35),
                BackColor = Color.Green,
                ForeColor = Color.White,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                FlatStyle = FlatStyle.Flat
            };
            _installButton.Click += InstallButton_Click;

            _uninstallButton = new Button
            {
                Text = "🗑️ Desinstalar",
                Location = new Point(240, 310),
                Size = new Size(120, 35),
                BackColor = Color.Orange,
                ForeColor = Color.White,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                FlatStyle = FlatStyle.Flat
            };
            _uninstallButton.Click += UninstallButton_Click;

            _exitButton = new Button
            {
                Text = "❌ Sair",
                Location = new Point(380, 310),
                Size = new Size(80, 35),
                BackColor = Color.Gray,
                ForeColor = Color.White,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                FlatStyle = FlatStyle.Flat
            };
            _exitButton.Click += (s, e) => Close();

            // Add warning about admin rights
            var adminLabel = new Label
            {
                Text = "⚠️ Este programa requer privilégios de administrador para modificar o registro do Windows.",
                Location = new Point(20, 360),
                Size = new Size(440, 40),
                Font = new Font("Segoe UI", 8),
                ForeColor = Color.DarkRed,
                TextAlign = ContentAlignment.MiddleCenter
            };

            // Add controls
            Controls.AddRange(new Control[] {
                _iconBox, titleLabel, subtitleLabel, _pathLabel, 
                _installPathLabel, _installPathTextBox, _browseButton,
                _statusLabel, _progressBar, _installButton, _uninstallButton, _exitButton, adminLabel
            });
        }

        private void CheckCurrentStatus()
        {
            try
            {
                using var key = Registry.ClassesRoot.OpenSubKey(@"Directory\Background\shell\OrganizarVLC\command");
                if (key?.GetValue("") is string command && !string.IsNullOrEmpty(command))
                {
                    _statusLabel.Text = "✅ Menu de contexto INSTALADO\n" +
                                      $"📋 Comando atual: {command}";
                    _statusLabel.ForeColor = Color.Green;
                    _installButton.Text = "🔄 Reinstalar";
                    _uninstallButton.Enabled = true;
                }
                else
                {
                    _statusLabel.Text = "❌ Menu de contexto NÃO INSTALADO\n" +
                                      "Clique em 'Instalar' para adicionar ao menu de contexto do Windows.";
                    _statusLabel.ForeColor = Color.Red;
                    _installButton.Text = "📥 Instalar Menu de Contexto";
                    _uninstallButton.Enabled = false;
                }
            }
            catch (Exception ex)
            {
                _statusLabel.Text = $"⚠️ Erro ao verificar status: {ex.Message}";
                _statusLabel.ForeColor = Color.Orange;
            }

            ValidateInstallPath();
        }

        private void ValidateInstallPath()
        {
            var installPath = GetCurrentInstallPath();
            
            // Verificar se o caminho é válido
            try
            {
                var fullPath = Path.GetFullPath(installPath);
                _installButton.Enabled = true;
                
                // Atualizar status se a validação está OK
                if (_statusLabel.ForeColor == Color.Red && _statusLabel.Text.Contains("ERRO"))
                {
                    CheckCurrentStatus();
                }
            }
            catch
            {
                _statusLabel.Text = "❌ ERRO: Caminho de instalação inválido!";
                _statusLabel.ForeColor = Color.Red;
                _installButton.Enabled = false;
            }
        }

        private void BrowseButton_Click(object? sender, EventArgs e)
        {
            using var folderDialog = new FolderBrowserDialog
            {
                Description = "Selecione onde instalar o VLC Organizer:",
                ShowNewFolderButton = true,
                SelectedPath = _installPathTextBox.Text
            };

            if (folderDialog.ShowDialog() == DialogResult.OK)
            {
                var selectedPath = folderDialog.SelectedPath;
                
                // Se não terminar com "VLC Organizer", adicionar
                if (!selectedPath.EndsWith("VLC Organizer", StringComparison.OrdinalIgnoreCase))
                {
                    selectedPath = Path.Combine(selectedPath, "VLC Organizer");
                }
                
                _installPathTextBox.Text = selectedPath;
                ValidateInstallPath();
                CheckCurrentStatus();
            }
        }

        private async void InstallButton_Click(object sender, EventArgs e)
        {
            if (!IsRunningAsAdmin())
            {
                MessageBox.Show(
                    "Este programa precisa ser executado como Administrador para modificar o registro do Windows.\n\n" +
                    "Por favor, clique com o botão direito no executável e selecione 'Executar como administrador'.",
                    "Privilégios de Administrador Requeridos",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning
                );
                return;
            }

            await InstallContextMenu();
        }

        private async void UninstallButton_Click(object sender, EventArgs e)
        {
            if (!IsRunningAsAdmin())
            {
                MessageBox.Show(
                    "Este programa precisa ser executado como Administrador para modificar o registro do Windows.",
                    "Privilégios de Administrador Requeridos",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning
                );
                return;
            }

            await UninstallContextMenu();
        }

        private async Task InstallContextMenu()
        {
            _progressBar.Visible = true;
            _installButton.Enabled = false;
            _uninstallButton.Enabled = false;

            try
            {
                _statusLabel.Text = "� Extraindo arquivos para instalação...";
                _statusLabel.ForeColor = Color.Blue;
                _progressBar.Value = 10;

                // Extrair arquivos embutidos
                ExtractEmbeddedFiles();
                
                _statusLabel.Text = "📝 Registrando menu de contexto...";
                _progressBar.Value = 25;

                // PowerShell command to execute the script
                var scriptPath = GetPowerShellScriptPath();
                var command = $"powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"{scriptPath}\" -PlaylistPath \"%V\"";

                // Register context menu for directory background
                using (var key = Registry.ClassesRoot.CreateSubKey(@"Directory\Background\shell\OrganizarVLC"))
                {
                    key.SetValue("", "🎬 Organizar esta Pasta com VLC");
                    key.SetValue("Icon", "shell32.dll,23");
                }

                _progressBar.Value = 50;

                using (var key = Registry.ClassesRoot.CreateSubKey(@"Directory\Background\shell\OrganizarVLC\command"))
                {
                    key.SetValue("", command);
                }

                _progressBar.Value = 75;

                // Also register for directory selection
                using (var key = Registry.ClassesRoot.CreateSubKey(@"Directory\shell\OrganizarVLC"))
                {
                    key.SetValue("", "🎬 Organizar Pasta com VLC");
                    key.SetValue("Icon", "shell32.dll,23");
                }

                using (var key = Registry.ClassesRoot.CreateSubKey(@"Directory\shell\OrganizarVLC\command"))
                {
                    key.SetValue("", command.Replace("%V", "%1"));
                }

                _progressBar.Value = 100;

                await Task.Delay(500); // Show completed progress

                _statusLabel.Text = "✅ INSTALAÇÃO CONCLUÍDA!\n\n" +
                                  "Arquivos extraídos e menu de contexto registrado.\n" +
                                  "Agora você pode clicar com o botão direito em qualquer pasta\n" +
                                  "e selecionar '🎬 Organizar esta Pasta com VLC'.";
                _statusLabel.ForeColor = Color.Green;

                MessageBox.Show(
                    "✅ Instalação concluída com sucesso!\n\n" +
                    $"📁 Arquivos instalados em: {GetCurrentInstallPath()}\n\n" +
                    "Como usar:\n" +
                    "1. Clique com o botão direito em qualquer pasta\n" +
                    "2. Selecione '🎬 Organizar esta Pasta com VLC'\n" +
                    "3. O organizador processará automaticamente os vídeos",
                    "Instalação Concluída",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );
            }
            catch (Exception ex)
            {
                _statusLabel.Text = $"❌ Erro durante instalação: {ex.Message}";
                _statusLabel.ForeColor = Color.Red;

                MessageBox.Show(
                    $"Erro durante a instalação:\n{ex.Message}",
                    "Erro na Instalação",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
            }
            finally
            {
                _progressBar.Visible = false;
                _installButton.Enabled = true;
                CheckCurrentStatus();
            }
        }

        private async Task UninstallContextMenu()
        {
            _progressBar.Visible = true;
            _installButton.Enabled = false;
            _uninstallButton.Enabled = false;

            try
            {
                _statusLabel.Text = "🗑️ Removendo menu de contexto...";
                _statusLabel.ForeColor = Color.Blue;
                _progressBar.Value = 50;

                // Remove registry entries
                try
                {
                    Registry.ClassesRoot.DeleteSubKeyTree(@"Directory\Background\shell\OrganizarVLC");
                }
                catch { /* Key might not exist */ }

                try
                {
                    Registry.ClassesRoot.DeleteSubKeyTree(@"Directory\shell\OrganizarVLC");
                }
                catch { /* Key might not exist */ }

                // Perguntar se deseja remover arquivos instalados
                var result = MessageBox.Show(
                    "Deseja também remover os arquivos instalados?\n\n" +
                    $"Pasta: {GetCurrentInstallPath()}\n\n" +
                    "Selecione 'Sim' para remover completamente ou 'Não' para manter os arquivos.",
                    "Remover Arquivos?",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Question
                );

                if (result == DialogResult.Yes)
                {
                    try
                    {
                        var installPath = GetCurrentInstallPath();
                        if (Directory.Exists(installPath))
                        {
                            Directory.Delete(installPath, true);
                            _statusLabel.Text = "✅ DESINSTALAÇÃO COMPLETA!\n\n" +
                                              "Menu de contexto removido e arquivos excluídos.";
                        }
                    }
                    catch (Exception ex)
                    {
                        _statusLabel.Text = "⚠️ Menu removido, mas não foi possível excluir arquivos:\n" + ex.Message;
                    }
                }
                else
                {
                    _statusLabel.Text = "✅ DESINSTALAÇÃO CONCLUÍDA!\n\n" +
                                      "Menu de contexto removido. Arquivos mantidos.";
                }

                _progressBar.Value = 100;
                await Task.Delay(500);
                _statusLabel.ForeColor = Color.Green;

                MessageBox.Show(
                    "✅ Desinstalação concluída!\n\nO menu de contexto foi removido do Windows.",
                    "Desinstalação Concluída",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );
            }
            catch (Exception ex)
            {
                _statusLabel.Text = $"❌ Erro durante desinstalação: {ex.Message}";
                _statusLabel.ForeColor = Color.Red;

                MessageBox.Show(
                    $"Erro durante a desinstalação:\n{ex.Message}",
                    "Erro na Desinstalação",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
            }
            finally
            {
                _progressBar.Visible = false;
                _installButton.Enabled = true;
                CheckCurrentStatus();
            }
        }

        private string? FindVLCPath()
        {
            var paths = new[]
            {
                @"C:\Program Files\VideoLAN\VLC\vlc.exe",
                @"C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
            };

            return paths.FirstOrDefault(File.Exists);
        }

        private static bool IsRunningAsAdmin()
        {
            using var identity = WindowsIdentity.GetCurrent();
            var principal = new WindowsPrincipal(identity);
            return principal.IsInRole(WindowsBuiltInRole.Administrator);
        }
    }
}