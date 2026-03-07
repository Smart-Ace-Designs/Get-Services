<#
============================================================================================================================
Script: Get-Services
Author: Smart Ace Designs

Notes:
This script is used to display a list all services on the local computer.
============================================================================================================================
#>

#region Settings
$SUPPORT_CONTACT = "Smart Ace Designs"
#endregion

#region Assemblies
Add-Type -AssemblyName System.Windows.Forms
#endregion

#region Appearance
[System.Windows.Forms.Application]::EnableVisualStyles()
#endregion

#region Controls
$FormMain = New-Object -TypeName System.Windows.Forms.Form
$GroupBoxMain = New-Object -TypeName System.Windows.Forms.GroupBox
$LabelServices = New-Object -TypeName System.Windows.Forms.Label
$DataGridViewServices = New-Object -TypeName System.Windows.Forms.DataGridView
$ButtonRun = New-Object -TypeName System.Windows.Forms.Button
$ButtonClose = New-Object -TypeName System.Windows.Forms.Button
$StatusStripMain = New-Object -TypeName System.Windows.Forms.StatusStrip
$ToolStripStatusLabelMain = New-Object -TypeName System.Windows.Forms.ToolStripStatusLabel
#endregion

#region Forms
$ShowFormMain =
{
    $FormWidth = 630
    $FormHeight = 460

    $FormMain.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -Id $PID).Path)
    $FormMain.Text = "Server Services"
    $FormMain.Font = New-Object -TypeName System.Drawing.Font("MS Sans Serif",8)
    $FormMain.ClientSize = New-Object -TypeName System.Drawing.Size($FormWidth,$FormHeight)
    $FormMain.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $FormMain.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $FormMain.MaximizeBox = $false
    $FormMain.AcceptButton = $ButtonRun
    $FormMain.CancelButton = $ButtonClose
    $FormMain.Add_Shown($FormMain_Shown)

    $GroupBoxMain.Location = New-Object -TypeName System.Drawing.Point(10,5)
    $GroupBoxMain.Size = New-Object -TypeName System.Drawing.Size(($FormWidth - 20),($FormHeight - 80))
    $FormMain.Controls.Add($GroupBoxMain)

    $LabelServices.Location = New-Object -TypeName System.Drawing.Point(15,15)
    $LabelServices.AutoSize = $true
    $LabelServices.Text = "Services:"
    $GroupBoxMain.Controls.Add($LabelServices)

    $DataGridViewServices.Location = New-Object -TypeName System.Drawing.Point(15,35)
    $DataGridViewServices.Size = New-Object -TypeName System.Drawing.Size(($FormWidth - 50),($FormHeight - 135))
    $DataGridViewServices.TabStop = $false
    $DataGridViewServices.RowTemplate.Height = 20
    $DataGridViewServices.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation
    $DataGridViewServices.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $DataGridViewServices.RowHeadersVisible = $false
    $DataGridViewServices.AllowUserToResizeRows = $false
    $DataGridViewServices.ReadOnly = $true
    $DataGridViewServices.AllowUserToAddRows = $false
    $DataGridViewServices.AllowUserToDeleteRows = $false
    $GroupBoxMain.Controls.Add($DataGridViewServices)

    $ButtonRun.Location = New-Object -TypeName System.Drawing.Point(($FormWidth - 175),($FormHeight - 60))
    $ButtonRun.Size = New-Object -TypeName System.Drawing.Size(75,25)
    $ButtonRun.TabIndex = 100
    $ButtonRun.Text = "Run"
    $ButtonRun.Add_Click($ButtonRun_Click)
    $FormMain.Controls.Add($ButtonRun)

    $ButtonClose.Location = New-Object -TypeName System.Drawing.Point(($FormWidth - 85),($FormHeight - 60))
    $ButtonClose.Size = New-Object -TypeName System.Drawing.Size(75,25)
    $ButtonClose.TabIndex = 101
    $ButtonClose.Text = "Close"
    $ButtonClose.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $FormMain.Controls.Add($ButtonClose)

    $StatusStripMain.SizingGrip = $false
    $StatusStripMain.Font = New-Object -TypeName System.Drawing.Font("MS Sans Serif",8)
    [void]$StatusStripMain.Items.Add($ToolStripStatusLabelMain)
    $FormMain.Controls.Add($StatusStripMain)

    [void]$FormMain.ShowDialog()
    $FormMain.Dispose()
}
#endregion

#region Functions
function Invoke-FormAction
{
    param
    (
        [Parameter(Mandatory, Position = 0)] [ScriptBlock]$Action,
        [Parameter(Position = 1)] [ScriptBlock]$Reset = $null,
        [Parameter(Position = 2)] [String]$StatusText = "Working...please wait"
    )

    try
    {
        $ToolStripStatusLabelMain.Text = $StatusText
        $FormMain.Controls | Where-Object {$PSItem -isnot [System.Windows.Forms.StatusStrip]} | ForEach-Object {$PSItem.Enabled = $false}
        $FormMain.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        [System.Windows.Forms.Application]::DoEvents()

        & $Action
    }
    
    finally
    {
        $FormMain.Controls | ForEach-Object {$PSItem.Enabled = $true}
        $FormMain.ResetCursor()
        if ($Reset) {& $Reset}
        $ToolStripStatusLabelMain.Text = "Ready"
        $StatusStripMain.Update()
    }
}
#endregion

#region Handlers
$FormMain_Shown =
{
    $ToolStripStatusLabelMain.Text = "Ready"
    $StatusStripMain.Update()
    $FormMain.Activate()
}

$ButtonRun_Click = 
{
    Invoke-FormAction -Action {
        try
        {
            $Services = Get-Service -ErrorAction SilentlyContinue | Select-Object DisplayName, Status | Sort-Object DisplayName
            if ($Services)
            {
                $DataGridViewServices.ColumnCount = 2
                $DataGridViewServices.ColumnHeadersVisible = $true
                $DataGridViewServices.Columns[0].Name = "Service Name"
                $DataGridViewServices.Columns[1].Name = "Status"

                $DataGridViewServices.Rows.Clear()
                $Services | ForEach-Object {$DataGridViewServices.Rows.Add($PSItem.DisplayName, $PSItem.Status)}
                
                $ColumnCount = $DataGridViewServices.Columns.Count
                $LastColumnIndex = $ColumnCount - 1
                foreach ($Column in $DataGridViewServices.Columns)
                {
                    if ($Column.Index -eq $ColumnCount - $LastColumnIndex) {$Column.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill}
                    else {$Column.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells}

                    $Column.SortMode = [System.Windows.Forms.DataGridViewColumnSortMode]::NotSortable
                    $Column.SortMode = [System.Windows.Forms.DataGridViewColumnSortMode]::Automatic
                }
                $FormMain.Refresh()
            }
            else
            {
                [void][System.Windows.Forms.MessageBox]::Show(
                    "No services found on this computer.",
                    "Information",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
        catch
        {
            [void][System.Windows.Forms.MessageBox]::Show(
                $PSItem.Exception.Message + "`n`nPlease contact $SUPPORT_CONTACT for technical support.",
                "Exception",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }
    }
}
#endregion

#region Main
Invoke-Command -ScriptBlock $ShowFormMain
#endregion
