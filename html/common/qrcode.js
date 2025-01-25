/* -*- Mode: javascript; indent-tabs-mode: nil; c-basic-offset: 2 -*- */

document.addEventListener('DOMContentLoaded', function () {
    const qrcode = document.getElementById('qrcode');
    const otp = qrcode.getAttribute('data-otp');
    const username = qrcode.getAttribute('data-username');
    const digits = qrcode.getAttribute('data-digits');
    const period = qrcode.getAttribute('data-period');
    const suffix = qrcode.getAttribute('data-suffix');
    new QRCode(qrcode, `otpauth://totp/${username}.${suffix}?secret=${otp}&digits=${digits}&period=${period}`);
});
