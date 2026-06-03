function ThetaInRadians = angleBtwNDVectors(vec1,vec2)
% angle in radians between two sets of N-D vectors (between 2D, 3D, 4D...
% vectors)

% INPUT:
%     vec1 = M x N [ i j k ...] each row is a vector
%     vec2 = P x N [ i j k ...] each row is a vector
    
% OUTPUT:
%     ThetaInRadians = M x P matrix comparing each vector (row) in vec1 to vec2
%     ThetaInRadians = M x M matrix if only one input

if nargin < 2
    vec2 = vec1;
end

vec12 = vec1*vec2';
vec1_norm = sqrt(sum(vec1.^2,2));
vec2_norm = sqrt(sum(vec2.^2,2));
vec_norm = vec1_norm*vec2_norm';

CosTheta = vec12./vec_norm;

ThetaInRadians = abs(acos(CosTheta));
end