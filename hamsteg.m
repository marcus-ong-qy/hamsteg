HAMM_ORDER = 6;
H = hammgen(HAMM_ORDER);
col_shuffle = randperm(size(H, 2));
H = H(:,col_shuffle);

table = syndtable(H);

% IMG_HT = MSG_LEN/HAMM_ORDER; 
% IMG_WT = 2^HAMM_ORDER-1;
% img = randi([0,255],IMG_HT,IMG_WT,'uint8');
IMG_WT = 2^HAMM_ORDER-1;
IMG_HT = IMG_WT; 
img = rgb2gray( ...
    imresize( ...
        imread('ayampenyet_small.jpg'), ...
        [IMG_HT IMG_WT]) ...
    );

MSG_LEN = HAMM_ORDER * IMG_HT;
% msg = randi([0,1],MSG_LEN,1);
encrypt_msg = 'tawakul owe me unlimited ayam penyet';
msg = string2bits(encrypt_msg,MSG_LEN)';

lsb_str_len = size(img,1)*size(img,2);
lsb_str = zeros(1,lsb_str_len);
crypt_str = zeros(1,lsb_str_len);

for i=1:size(img,1)
    for j=1:size(img,2)
        lsb = get_lsb(img(i,j));
        lsb_str((i-1)*IMG_HT+j) = lsb;
    end
end

for i=1:IMG_WT:lsb_str_len
    x = lsb_str(i:i+IMG_WT-1)';
    msg_ext = msg( ...
        ((i-1)/IMG_WT)*HAMM_ORDER+1: ...
        ((i-1)/IMG_WT)*HAMM_ORDER+HAMM_ORDER ...
    );
    s = mod(msg_ext - H*x,2);
    syndId = bi2de(s','left-msb');
    eL = table(syndId+1,:)'; % smiley face hehehehe :)
    y = mod(x + eL,2);
    crypt_str(i:i+IMG_WT-1) = y;
end

new_crypt_img = img_overwrite_lsb(img,crypt_str);

%% decryption

% receiver side recieives the following information:
HAMM_ORDER; % order of Hamming matrix used
col_shuffle; % order of columns shuffled from default Hamming matrix
new_crypt_img; % encrypted image

dec_H = hammgen(HAMM_ORDER);
dec_H = dec_H(:,col_shuffle);

crypt_img_ht = size(new_crypt_img,1);
crypt_img_wt = size(new_crypt_img,2);
crypt_str_len = crypt_img_ht*crypt_img_wt;

decrypt_msg_bitstr = zeros(crypt_str_len,1);
extracted_crypt_str = img_extract_lsb(new_crypt_img);

for j=1:crypt_img_wt:lsb_str_len
    y = extracted_crypt_str(j:j+crypt_img_wt-1)';
    mp = dec_H*y;
    decrypt_msg_bitstr( ...
        ((j-1)/crypt_img_wt)*HAMM_ORDER+1: ...
        ((j-1)/crypt_img_wt)*HAMM_ORDER+HAMM_ORDER ...
    ) = mod(mp,2);
end

decrypt_msg = bits2string(decrypt_msg_bitstr');

sprintf('original message: %s', encrypt_msg)
sprintf('decrypted message: %s', decrypt_msg)


figure
hold on
subplot(2,1,1)
imshow(mat2gray(imresize(img, 300, 'nearest'),[0,255]))
title('cover img')
subplot(2,1,2)
imshow(mat2gray(imresize(new_crypt_img, 300, 'nearest'),[0,255]))
title('encrypted img')
hold off

figure
hold on
subplot(1,4,1)
imagesc(msg)
title('Binary message')
subplot(1,3,2)
imagesc(crypt_str')
title('Encrypted bit vector')
subplot(1,3,3)
imagesc(decrypt_msg_bitstr(1:MSG_LEN))
title('Decrypted bin msg')
hold off


function lsb = get_lsb(x)
    lsb = mod(x,2);
end

function new_px = overwrite_lsb(px,new_lsb)
    if (mod(px,2) == 1)
        if new_lsb == 0
            new_px = px - 1;
        else
            new_px = px;
        end
    else
        if new_lsb == 1
            new_px = px + 1;
        else
            new_px = px;
        end
    end
end

function new_img = img_overwrite_lsb(img,cover_px)
    img_ht = size(img,1);
    img_wt = size(img,2);
    new_img = img;
    
    if img_ht*img_wt ~= size(cover_px,2)
        fig = uifigure;
        uialert(fig, 'Overwrite Fail', "Size of inputs don't equal"); 
    end
    
    for i=1:img_ht
        for j=1:img_wt
            px_val = img(i,j);
            new_lsb = cover_px(1,(i-1)*img_wt + j);
            new_px_val = overwrite_lsb(px_val, new_lsb);
            new_img(i,j) = new_px_val;
        end
    end
end

function cover_px = img_extract_lsb(img)
    img_ht = size(img,1);
    img_wt = size(img,2);
    cover_px_len = img_ht*img_wt;
    cover_px = zeros(1,cover_px_len);
    
    for i=1:img_ht
        for j=1:img_wt
            px_val = img(i,j);
            new_lsb = get_lsb(px_val);
            cover_px(1,(i-1)*img_wt + j) = new_lsb;
        end
    end
end


function bit_str = string2bits(str,bit_len)
    str_len = size(str,2);
    if str_len*8 > bit_len
        fig = uifigure;
        uialert(fig, ...
            sprintf('Not Enough bits (bit_len=%d*8) to store message (str_len =%d)!', ...
            bit_len/8, str_len), 'Not Enough Storage' ...
        ); 
    end  

    bit_str = zeros(1,bit_len);
    for i=1:str_len
        char = str(i);
        char_val = uint8(char);
        char_bits = de2bi(char_val,8,'left-msb');
        bit_str((i-1)*8+1:i*8) = char_bits;
    end
end

function str = bits2string(bit_str)
    str = "";
    bit_str_len = size(bit_str,2);
    for i=1:8:bit_str_len
        if i+7 > bit_str_len 
            break
        end
        char_bits = bit_str(i:i+7);
        char_val = bi2de(char_bits,'left-msb');
        if char_val == 0
            break
        end
        character = char(char_val);
        str = str + character;
    end
end

