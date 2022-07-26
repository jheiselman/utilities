Set-StrictMode -Version Latest

# Corporate password rules
# * Have exactly 8 characters
# * have upper and lower case characters
# * not have more than 6 upper-case letters
# * not have more than 6 lower-case letters
# * have at least 1 digit
# * not be an old password (not likely with this tool)
# * not contain any non-alphanumeric characters except: @ # $
# * not contain 3 or more consecutive characters from a selected login ID
# * not contain 3 or more consecutive characters of first or last name
# * not contain words or combinations of characters easily guessed

Function New-Password () {
    $max_uppers = 6
    $max_lowers = 6
    $password_length = 8

    $number_of_uppers = 0
    $number_of_lowers = 0
    $number_of_digits = 0

    # Allowed chars (A-Z, a-z, 0-9, @, #, $)
    $chars = $null
    # This covers # and A-Z
    for ($a=64; $a -le 90; $a++) {
        $chars += ,[char][byte]$a
    }
    # This covers a-z
    for ($a=97; $a -le 122; $a++) {
        $chars += ,[char][byte]$a
    }
    # This covers 0-9
    for ($a=48; $a -le 57; $a++) {
        $chars += ,[char][byte]$a
    }
    $chars += ,[char][byte]35 # char = #
    $chars += ,[char][byte]36 # char = $

    $tempPass = ""
    for ($loop=1; $loop -le $password_length; $loop++) {
        $char = ($chars | Get-Random)
        if ([char]::IsDigit($char)) {
            $number_of_digits++;
            $tempPass += $char
        }
        if ([char]::IsLetter($char)) {
            if ([char]::IsUpper($char)) {
                if ($number_of_uppers -le $max_uppers) {
                    $tempPass += $char
                    $number_of_uppers++
                } else {
                    # We need to ignore this loop
                    $loop--
                }
            } else {
                if ($number_of_lowers -le $max_lowers) {
                    $tempPass += $char
                    $number_of_lowers++
                } else {
                    # We need to ignore this loop
                    $loop--
                }
            }
        }
    }

    if ($number_of_digits -eq 0) {
        $char_to_replace = Get-Random -Maximum 8 -Minimum 0
        $new_char = Get-Random -Maximum 9 -Minimum 0
        $tempPasswordArray = $tempPass.ToCharArray()
        $tempPasswordArray[$char_to_replace] = $new_char
        $tempPass = $tempPasswordArray -join ""
    }

    return $tempPass
}