/**
 * Copyright (C) 2014 Virgil Security Inc.
 *
 * Lead Maintainer: Virgil Security Inc. <support@virgilsecurity.com>
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     (1) Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *
 *     (2) Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in
 *     the documentation and/or other materials provided with the
 *     distribution.
 *
 *     (3) Neither the name of the copyright holder nor the names of its
 *     contributors may be used to endorse or promote products derived from
 *     this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <virgil/stream/utils.h>

#include <virgil/VirgilException.h>
using virgil::VirgilException;

#include <iostream>
#include <fstream>
#include <algorithm>
#include <iterator>

static bool is_asn1(const VirgilByteArray& data) {
    return data.size() > 0 && data[0] == 0x30;
}

VirgilCertificate virgil::stream::read_certificate(const std::string& fileName) {
    std::ifstream certificateFile(fileName.c_str(), std::ios::in | std::ios::binary);
    return virgil::stream::read_certificate(certificateFile, fileName);
}

VirgilCertificate virgil::stream::read_certificate(std::istream& file, const std::string& fileName) {
    if (!file.good()) {
        throw VirgilException(std::string("can not read certificate from file: " + fileName));
    }
    VirgilByteArray certificateData;
    std::copy(std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>(),
            std::back_inserter(certificateData));
    if (certificateData.empty()) {
        throw VirgilException(std::string("certificate file is empty: ") + fileName);
    }
    VirgilCertificate certificate;
    if (is_asn1(certificateData)) {
        // ASN.1 format
        certificate.fromAsn1(certificateData);
    } else {
        // JSON format
        certificate.fromJson(certificateData);
    }
    return certificate;
}

VirgilSign virgil::stream::read_sign(const std::string& fileName) {
    std::ifstream signFile(fileName.c_str(), std::ios::in | std::ios::binary);
    return virgil::stream::read_sign(signFile, fileName);
}

VirgilSign virgil::stream::read_sign(std::istream& file, const std::string& fileName) {
    if (!file.good()) {
        throw VirgilException(std::string("can not read sign from file: " + fileName));
    }
    VirgilByteArray signData;
    std::copy(std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>(),
            std::back_inserter(signData));
    if (signData.empty()) {
        throw VirgilException(std::string("sign file is empty: ") + fileName);
    }
    VirgilSign sign;
    if (is_asn1(signData)) {
        // ASN.1 format
        sign.fromAsn1(signData);
    } else {
        // JSON format
        sign.fromJson(signData);
    }
    return sign;
}