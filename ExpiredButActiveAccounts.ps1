<#	
	.NOTES
	===========================================================================
    Created on:   	20230629 16:00 PM
    Created by:   	Arnaud FERRIERE
    Version: 	    1.0.0

    Notes:
	The variables you should change are :
	$DCBase : Can be left empty to search all the AD you're connected to
    $SMTPHost
    $SMTPPort
    $MailSubject
    $MailSender
    $MailRecipient
    $MailBody

    This sends the mail in html format so accented characters can be used while still keeping the table format for the users list. You could easily send it in plain text instead.
	===========================================================================
	.DESCRIPTION
		This script will send an e-mail notification to the selected mail listing all account expired but not disabled.
        It prevents support from missing a departed user.

		It will look for the users with active accounts, and with an expiration date in the AccountExpirationDate attribute prior to the current date. 
        If there is one or more active and expired accounts, it will send a mail to the selected recipient.
#>

#VARs
#DC Base
$DCBase = 'DC=domain,DC=com'
#SMTP Host
$SMTPHost = 'smtp.host'
#SMTP Port
$SMTPPort = 'port'
#The subject of your mail
$MailSubject = 'Notification : Expired user accounts not disabled'
#Who is the mail sent from ?
$MailSender = 'sender@domain'
#Whos is the mail sent to ?
$MailRecipient = 'recipient@domain'

#CODE
#We start by importing the ActiveDirectory module
"INFO: Importing Active Directory Module "
Import-Module ActiveDirectory

#Set $AccountExpiredActive for expired accounts prior to current date but still active, then select OU, Name, Username and expiration date
$AccountExpiredActive = Get-ADUser -Filter * -SearchBase $DCBase -properties AccountExpirationDate | Where-Object{$_.AccountExpirationDate -lt (Get-Date) -and $_.AccountExpirationDate -ne $null -and $_.Enabled -eq $True} | select-object @{Name="OrganizationalUnit"; Expression={$_.DistinguishedName -replace ".*,OU=(.*?),.*",'OU=$1'}}, Name, SamAccountName, AccountExpirationDate

#If there are accounts, we send them.
if ($AccountExpiredActive) {
    "INFO: Matching users found. Sending mail"
$MailBody = @"
<html>
<head>
<meta http-equiv='Content-Type' content='text/html; charset=utf-8'><!--needed it you use accented characters-->
<style>
    body {
      font:
        14px Arial,
        Helvetica,
        sans-serif;
    }

    .table_users {
      background-color: white;
      border: 1px solid black;
    }

  </style>
</head>
<body>
        <p>Hello there !</p>
        <p>Here's a list of users expired but still active.</p>
        <br />
        <table class="table_users">
        <tbody>
        <tr>
        <td>
        $($AccountExpiredActive | ConvertTo-Html -Fragment)
        </td>
        </tr>
        </tbody>
        </table>
        <br />
        <p><i>this is an automatically generated notification
        </i></p>

</body>
</html>
"@

Send-MailMessage -To $MailRecipient -From $MailSender -Subject $MailSubject -Body $MailBody -BodyAsHtml -SmtpServer $SMTPHost -Port $SMTPPort

"INFO: Mail sent"
}

"INFO : No accounts were matching. End of work."
