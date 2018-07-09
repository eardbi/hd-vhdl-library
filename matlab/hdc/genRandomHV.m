function randomHV = genRandomHV(D)

if(mod(D,2))
    disp('Dimension is odd!!');
    return;
end

randomHV = zeros(1,D);
randomIndex = randperm(D);
randomHV(randomIndex(1:round(D/2))) = 1;


end