//
//  FeedCellWithCarousel.swift
//  VK-Challenge
//
//  Created by Evgeniy on 11/11/2018.
//  Copyright © 2018 Evgeniy. All rights reserved.
//

import UIKit

final class FeedCellWithCarousel: UICollectionViewCell, AnyFeedCell {
    // MARK: - Interface

    weak var expandDelegate: FeedCellExpandDelegate?

    private var isExpanded = false

    // MARK: - Outlets

    // ==== Header

    @IBOutlet
    private var avatarImageView: UIImageView!

    @IBOutlet
    private var titleLabel: UILabel!

    @IBOutlet
    private var dateLabel: UILabel!

    // ==== Content

    @IBOutlet
    private var contentLabel: UILabel!

    @IBOutlet
    private var postImageCollection: UICollectionView!

    @IBOutlet
    private var postImagePageControl: UIPageControl!

    // ==== Footer

    @IBOutlet
    private var footerView: UIView!

    @IBOutlet
    private var footerSeparator: UIView!

    @IBOutlet
    private var likeImageView: UIImageView!

    @IBOutlet
    private var likesCountLabel: UILabel!

    @IBOutlet
    private var commentImageView: UIImageView!

    @IBOutlet
    private var commentsCountLabel: UILabel!

    @IBOutlet
    private var repostImageView: UIImageView!

    @IBOutlet
    private var repostsCountLabel: UILabel!

    @IBOutlet
    private var viewsCountImageView: UIImageView!

    @IBOutlet
    private var viewsCountLabel: UILabel!

    // MARK: - Private

    private lazy var pan
        = UITapGestureRecognizer(target: self, action: #selector(toggleTextCollapse))

    private var avatarLoadingTask: URLSessionDataTask?

    private var postImageLoadingTasks: [URLSessionDataTask] = []

    private var viewModel: FeedCellViewModel?

    // MARK: - Methods

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil

        avatarLoadingTask?.cancel()
        avatarLoadingTask = nil

        postImageLoadingTasks.forEach { $0.cancel() }
        postImageLoadingTasks = []

        isExpanded = false
        postImageCollection.contentOffset.x = -12
        postImagePageControl.currentPage = 0
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        setupCell()
    }

    private func setupCell() {
        clipsToBounds = false
        backgroundColor = .clear
        layer.shadowOffset = CGSize(width: 0, height: 24)
        layer.shadowRadius = 9
        layer.shadowOpacity = 0.07
        layer.shadowColor = UIColor.rgb(99, 103, 111).cgColor

        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true

        contentLabel.isUserInteractionEnabled = true
        contentLabel.addGestureRecognizer(pan)

        postImageCollection.register(FeedCellCarouselCell.self)
        postImageCollection.dataSource = self
        postImageCollection.delegate = self
        postImageCollection.contentInset.left = 12
        postImageCollection.contentInset.right = postImageCollection.contentInset.left

        setupPageControl()
    }

    private func setupPageControl() {
        postImagePageControl.addTarget(self, action: #selector(changePage(_:)), for: .valueChanged)
    }

    @objc
    private func changePage(_ sender: UIPageControl) {
        let page = sender.currentPage
        guard postImageCollection.numberOfItems(inSection: 0) >= page else { return }

        let newPath = IndexPath(row: page, section: 0)
        postImageCollection.scrollToItem(at: newPath, at: .centeredHorizontally, animated: true)
    }

    // MARK: - Setup

    func setup(with viewModel: FeedCellViewModel, isExpanded: Bool = false) {
        self.viewModel = viewModel
        self.isExpanded = isExpanded

        titleLabel.text = viewModel.titleText
        dateLabel.text = viewModel.dateText
        likesCountLabel.text = viewModel.likesCount.stringValue
        commentsCountLabel.text = viewModel.commentsCount.stringValue
        repostsCountLabel.text = viewModel.repostCount.stringValue
        viewsCountImageView.isHidden = viewModel.viewsCount == nil
        viewsCountLabel.text = viewModel.viewsCount?.stringValue

        if isExpanded {
            contentLabel.attributedText = viewModel.contentText
        } else {
            contentLabel.attributedText = viewModel.shortText ?? viewModel.contentText
        }

        avatarLoadingTask = viewModel.imageLoader.load(from: viewModel.avatarURL) { [weak self] image in
            self?.avatarImageView.image = image
        }

        postImageCollection.reloadData()
        layoutViewsCount()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        layoutHeader()
        layoutContent()
        layoutFooter()
    }

    private func layoutHeader() {
        avatarImageView.frame.size = CGSize(width: 36, height: 36)
        avatarImageView.frame.origin = CGPoint(x: 12, y: 12)
        avatarImageView.layer.cornerRadius = avatarImageView.frame.height / 2

        let maxLeftX = avatarImageView.frame.maxX

        titleLabel.frame.size = CGSize(width: frame.width - maxLeftX - 10 - 12, height: titleLabel.font.lineHeight)
        titleLabel.frame.origin = avatarImageView.frame.origin
        titleLabel.frame.origin.x = maxLeftX + 10

        dateLabel.frame.size = titleLabel.frame.size
        dateLabel.frame.size.height = dateLabel.font.lineHeight
        dateLabel.frame.origin = titleLabel.frame.origin
        dateLabel.frame.origin.y = titleLabel.frame.maxY + 1
    }

    private func layoutContent() {
        let maxY = avatarImageView.frame.maxY
        contentLabel.frame.size.width = frame.width - 24
        contentLabel.frame.size.height = frame.height - maxY - 10 - 6 - 44 - 38
        contentLabel.frame.origin = CGPoint(x: 12, y: maxY + 10)

        guard let viewModel = viewModel else { return }
        contentLabel.frame.size.height -= viewModel.photoHeight
        if viewModel.contentText.length == 0 {
            contentLabel.frame.size = .zero
        }

        postImageCollection.frame.size.width = frame.width
        postImageCollection.frame.size.height = viewModel.photoHeight
        postImageCollection.frame.origin = CGPoint(x: 0, y: contentLabel.frame.maxY + 6)

        postImagePageControl.numberOfPages = viewModel.postImages.count
        postImagePageControl.sizeToFit()
        postImagePageControl.center.x = center.x
        postImagePageControl.frame.origin.y = postImageCollection.frame.maxY
    }

    private func layoutFooter() {
        footerView.frame.size.width = frame.width
        footerView.frame.size.height = 44
        footerView.frame.origin.x = 0
        footerView.frame.origin.y = frame.height - 44

        footerSeparator.frame.size.width = frame.width - 24
        footerSeparator.frame.size.height = 0.5
        footerSeparator.frame.origin = CGPoint(x: 12, y: 0)

        likeImageView.frame.size = CGSize(width: 24, height: 24)
        likeImageView.frame.origin = CGPoint(x: 16, y: 10)

        var maxLeftX = likeImageView.frame.maxX
        let labelsWidth = (frame.width / 4.3) - 40

        likesCountLabel.frame.size.width = labelsWidth
        likesCountLabel.frame.size.height = likesCountLabel.font.lineHeight
        likesCountLabel.center.y = likeImageView.center.y
        likesCountLabel.frame.origin.x = maxLeftX + 4
        maxLeftX = likesCountLabel.frame.maxX

        commentImageView.frame.size = CGSize(width: 24, height: 24)
        commentImageView.center.y = likeImageView.center.y
        commentImageView.frame.origin.x = maxLeftX + 16
        maxLeftX = commentImageView.frame.maxX

        commentsCountLabel.frame.size.width = labelsWidth
        commentsCountLabel.frame.size.height = commentsCountLabel.font.lineHeight
        commentsCountLabel.center.y = likeImageView.center.y
        commentsCountLabel.frame.origin.x = maxLeftX + 4
        maxLeftX = commentsCountLabel.frame.maxX

        repostImageView.frame.size = CGSize(width: 24, height: 24)
        repostImageView.center.y = likeImageView.center.y
        repostImageView.frame.origin.x = maxLeftX + 16
        maxLeftX = repostImageView.frame.maxX

        repostsCountLabel.frame.size.width = labelsWidth
        repostsCountLabel.frame.size.height = repostsCountLabel.font.lineHeight
        repostsCountLabel.center.y = likeImageView.center.y
        repostsCountLabel.frame.origin.x = maxLeftX + 4
        maxLeftX = repostsCountLabel.frame.maxX

        layoutViewsCount()
    }

    private func layoutViewsCount() {
        viewsCountLabel.sizeToFit()
        viewsCountLabel.center.y = likeImageView.center.y
        viewsCountLabel.frame.origin.x = frame.width - 16 - viewsCountLabel.frame.width

        viewsCountImageView.frame.size = CGSize(width: 20, height: 20)
        viewsCountImageView.center.y = likeImageView.center.y
        viewsCountImageView.frame.origin.x = viewsCountLabel.frame.minX - 2 - 20
    }

    // MARK: - Actions

    @objc
    private func toggleTextCollapse() {
        guard viewModel?.shortText != nil else { return }
        isExpanded.toggle()

        expandDelegate?.cell(self, wantsExpand: isExpanded)

        if isExpanded {
            contentLabel.attributedText = viewModel?.contentText
        } else {
            contentLabel.attributedText = viewModel?.shortText
        }
    }
}

private extension Int {
    var stringValue: String? {
        return self > 0 ? "\(self)" : nil
    }
}

extension FeedCellWithCarousel: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.postImages.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: FeedCellCarouselCell = collectionView.dequeueReusableCell(at: indexPath)
        if let postImageURL = getPostImageURL(at: indexPath) {
            viewModel?.imageLoader.load(from: postImageURL) { [weak cell] image in
                cell?.setImage(image)
            }
        }

        return cell
    }

    private func getPostImageURL(at indexPath: IndexPath) -> String? {
        guard let viewModel = viewModel else { return nil }

        return viewModel.postImages[indexPath.row]
    }
}

extension FeedCellWithCarousel: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let viewModel = viewModel else { return .zero }

        return CGSize(width: frame.width - 24, height: viewModel.photoHeight)
    }
}

extension FeedCellWithCarousel {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        postImagePageControl.currentPage = Int(pageNumber)
    }
}
