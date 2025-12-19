# macOS-specific Configuration

# SSH agent with Keychain
if [ -f ~/.ssh/id_rsa ]; then
    nohup ssh-add --apple-use-keychain ~/.ssh/id_rsa > /dev/null 2>&1 & disown
fi

# Azure credentials (if needed - consider moving to Bitwarden)
export AZURE_TENANT_ID=efce8346-592b-4b6e-b1c2-0fd07bd5e442
export AZURE_APP_ID_URI=https://signin.aws.amazon.com/saml
export AZURE_DEFAULT_USERNAME=urbanb@netrtl.com
export AZURE_DEFAULT_DURATION_HOURS=12
